#!/usr/bin/env rails runner

puts "=" * 80
puts "SYNC BASE_SKILLS FROM OCTOBER 2025 UPDATES"
puts "=" * 80
puts ""

# Define all the skill updates from Oct 7-13
skill_updates = {
  1 => { cd: 10.0, duration: 8.0 },           # Oct 12: FireTornado
  2 => { duration: 7.0 },                      # Oct 7: RepairDrone
  8 => { duration: 4.0 },                      # Oct 11: SacredSlash (Rowan)
  10 => { cd: 8.0, duration: 6.0 },           # Oct 13: Inferno (Cedric)
  12 => { duration: 8.0 },                     # Oct 13: Ice_Spike (Morgath)
  15 => { damage_ratio: 2.0 },                 # Oct 9: PoisonDartVolley (Velan)
  16 => { duration: 6.0 },                     # Oct 10: HowlingBlizzard (Ragnar)
  18 => { duration: 10.0 },                    # Oct 11: FoxFireWhirlwind (Ugra)
  20 => { name: 'Skill_FairyWindDance' }       # Oct 9: Nyx skill changed
}

puts "[STEP 1] Current state in US database:"
skill_updates.each do |id, expected|
  skill = BaseSkill.find_by(id: id)
  if skill
    puts "  ID #{id}: #{skill.name}"
    expected.each do |field, value|
      current = skill.send(field)
      status = current == value ? "✓" : "✗"
      puts "    #{status} #{field}: #{current} (expected: #{value})" if !expected.empty?
    end
  end
end

puts ""
puts "[STEP 2] Changes to apply:"
total_changes = 0
skill_updates.each do |id, changes|
  total_changes += changes.size
  puts "  ID #{id}: #{changes.inspect}"
end

puts ""
puts "[STEP 3] Preview: #{total_changes} field updates across #{skill_updates.size} skills"
puts ""

# Confirmation
print "Type 'SYNC' to apply all Oct updates to US database: "
confirmation = STDIN.gets.chomp

unless confirmation == 'SYNC'
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

      puts "  [ID #{id}] #{skill.name}"
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
