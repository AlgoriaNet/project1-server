#!/usr/bin/env rails runner

puts "=" * 80
puts "SYNC ALL MISSING SKILL UPDATES FROM OCTOBER 2025"
puts "=" * 80
puts ""

# Define all the skill updates that were in Beijing DB but missing from US DB
skill_updates = {
  2 => {
    name: 'Skill_RepairDrone',
    duration: 7.0
  },
  8 => {
    name: 'Skill_SacredSlash',
    duration: 4.0,
    damage_ratio: 2.0,
    two_stage_damage_ratio: 2.0,
    three_stage_damage_ratio: 3.0
  },
  15 => {
    name: 'Skill_PoisonDartVolley',
    duration: 2.0,
    damage_ratio: 2.0,
    two_stage_damage_ratio: 2.0,
    three_stage_damage_ratio: 3.0
  },
  16 => {
    name: 'Skill_HowlingBlizzard',
    cd: 12.0,
    duration: 6.0,
    damage_ratio: 1.5,
    two_stage_damage_ratio: 1.5,
    three_stage_damage_ratio: 2.25,
    damage_type: 'Ice'
  },
  18 => {
    name: 'Skill_FoxFireWhirlwind',
    cd: 15.0,
    duration: 10.0,
    damage_ratio: 1.5,
    two_stage_damage_ratio: 1.5,
    three_stage_damage_ratio: 2.25
  }
}

puts "[STEP 1] Current state in US database (BEFORE sync):"
puts ""
skill_updates.each do |id, expected|
  skill = BaseSkill.find_by(id: id)
  if skill
    puts "  ID #{id}: #{skill.name}"
    expected.each do |field, value|
      current = skill.send(field)
      status = current == value ? "✓" : "✗"
      puts "    #{status} #{field}: #{current} (expected: #{value})" if field != :name || current != value
    end
  end
end

puts ""
puts "[STEP 2] Changes to apply:"
total_changes = 0
skill_updates.each do |id, changes|
  total_changes += changes.size
  sidekick = BaseSidekick.where(skill_id: BaseSkill.find(id).id).first
  sidekick_name = sidekick ? sidekick.name : "Unknown"
  puts "  ID #{id} (#{sidekick_name}): #{changes.inspect}"
end

puts ""
puts "[STEP 3] Preview: #{total_changes} field updates across #{skill_updates.size} skills"
puts ""

# Confirmation
print "Type 'SYNC_SKILLS' to apply all missing skill updates to US database: "
confirmation = STDIN.gets.chomp

unless confirmation == 'SYNC_SKILLS'
  puts "❌ Cancelled. No changes made."
  exit 0
end

puts ""
puts "[STEP 4] Applying updates in transaction..."
puts ""

begin
  ApplicationRecord.transaction do
    updated_count = 0

    skill_updates.each do |id, changes|
      skill = BaseSkill.find_by(id: id)
      next unless skill

      sidekick = BaseSidekick.where(skill_id: skill.id).first
      sidekick_name = sidekick ? sidekick.name : "Unknown"
      puts "  [ID #{id}] #{sidekick_name} (#{skill.name})"

      changes.each do |field, value|
        old_value = skill.send(field)
        skill.send("#{field}=", value)
        puts "    ✓ #{field}: #{old_value} → #{value}"
        updated_count += 1
      end

      skill.save!
    end

    puts ""
    puts "=" * 80
    puts "SUMMARY"
    puts "=" * 80
    puts "  Total field updates: #{updated_count}"
    puts ""

    # Verify
    puts "[STEP 5] Verifying updates:"
    all_correct = true
    skill_updates.each do |id, expected|
      skill = BaseSkill.find_by(id: id)
      next unless skill

      correct = true
      expected.each do |field, value|
        correct = false unless skill.send(field) == value
      end

      status = correct ? "✓" : "✗"
      puts "  #{status} ID #{id}: #{skill.name}"
      all_correct = false unless correct
    end

    puts ""
    if all_correct
      puts "✓ All updates verified!"
    else
      puts "✗ Some updates failed verification"
    end

    puts ""
    print "Confirm permanent commit? Type 'YES': "
    final_confirm = STDIN.gets.chomp

    if final_confirm == 'YES'
      puts "✅ Changes committed to database"
    else
      puts "⚠️  Rolling back..."
      raise ActiveRecord::Rollback
    end
  end

rescue ActiveRecord::Rollback
  puts "❌ Transaction rolled back. Database unchanged."
rescue => e
  puts "❌ ERROR: #{e.message}"
  puts e.backtrace.first(5).join("\n")
  puts "⚠️  Transaction automatically rolled back."
end

puts ""
puts "Done."
