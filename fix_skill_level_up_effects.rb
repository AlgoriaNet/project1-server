#!/usr/bin/env rails runner

puts "=" * 80
puts "SAFE FIX: SKILL LEVEL UP EFFECTS FOR US DATABASE"
puts "=" * 80
puts ""

# STEP 1: INSPECT CURRENT STATE
puts "[STEP 1] Inspecting current database state..."
current_count = BaseSkillLevelUpEffect.count
puts "  Current BaseSkillLevelUpEffect records: #{current_count}"
puts ""

# STEP 2: DEFINE THE CORRECT DATA STRUCTURE
puts "[STEP 2] Defining correct skill effects structure..."
effects_structure = {
  1 => :skill_name,  # Special: will use base_skill.name
  3 => { "ExtraDamageGain" => "0.20" },
  6 => { "ReduceCd" => "1.0" },
  9 => { "ExtraDamageGain" => "0.35" },
  12 => { "AddDuration" => "2.0" },
  15 => { "AddReleaseCount" => "1" },
  18 => { "ReduceCd" => "2.0" },
  20 => { "ExtraDamageGain" => "0.50" }
}

puts "  Levels to fix: #{effects_structure.keys.sort.join(', ')}"
puts ""

# STEP 3: PREVIEW CHANGES FOR FIRST SIDEKICK
puts "[STEP 3] Previewing changes for first sidekick..."
first_sidekick = BaseSidekick.first
first_skill = BaseSkill.find(first_sidekick.skill_id)

puts "  Sidekick: #{first_sidekick.name}"
puts "  Skill: #{first_skill.name}"
puts ""

effects_structure.each do |level, effect_data|
  if effect_data == :skill_name
    puts "  L#{level.to_s.rjust(2, '0')}: #{first_skill.name} (skill name)"
  else
    puts "  L#{level.to_s.rjust(2, '0')}: #{effect_data.inspect}"
  end
end

puts ""

# STEP 4: COUNT CHANGES
puts "[STEP 4] Planning updates..."
all_sidekicks = BaseSidekick.all
total_to_update = 0

all_sidekicks.each do |sidekick|
  effects_structure.keys.each do |level|
    record = BaseSkillLevelUpEffect.find_by(skill_id: sidekick.skill_id, level: level)
    if record
      total_to_update += 1
    end
  end
end

puts "  Total skill level records to update: #{total_to_update}"
puts "  (20 sidekicks × 7 levels)"
puts ""

# STEP 5: CONFIRMATION
puts "[STEP 5] Requesting confirmation..."
puts "This will update ALL skill level effects (L01, L03, L06, L09, L12, L15, L18, L20)"
puts "for all 20 sidekicks."
puts ""
puts "SAFE: Only updates existing records, no deletes or creates"
puts ""
print "Type 'FIX' to proceed: "
confirmation = STDIN.gets.chomp

unless confirmation == 'FIX'
  puts "❌ Cancelled. No changes made."
  exit 0
end

puts ""
puts "[STEP 6] Starting transaction..."
puts ""

# STEP 6: BEGIN TRANSACTION
begin
  ApplicationRecord.transaction do
    updated_count = 0
    errors = []

    all_sidekicks.each do |sidekick|
      skill = BaseSkill.find(sidekick.skill_id)

      effects_structure.each do |level, effect_data|
        record = BaseSkillLevelUpEffect.find_by(skill_id: sidekick.skill_id, level: level)

        unless record
          errors << "Missing: Skill #{sidekick.skill_id} (#{sidekick.name}), Level #{level}"
          next
        end

        # Determine the effect value
        if effect_data == :skill_name
          # Use the skill name as the effect
          new_effects = { "SkillName" => skill.name }
        else
          # Use the provided effect data
          new_effects = effect_data
        end

        old_effects = record.effects.inspect

        # Update the record
        record.update!(effects: new_effects.to_json)
        updated_count += 1

        puts "  [#{sidekick.name}] L#{level.to_s.rjust(2, '0')}: #{new_effects.inspect}"
      end
    end

    puts ""
    puts "=" * 80
    puts "TRANSACTION SUMMARY"
    puts "=" * 80
    puts "  Records updated: #{updated_count}"
    puts "  Errors: #{errors.count}"

    if errors.any?
      puts ""
      puts "ERRORS:"
      errors.each { |e| puts "    - #{e}" }
    end

    puts ""

    # STEP 7: VERIFY
    puts "[STEP 7] Verifying data (within transaction)..."

    # Check a sample
    sample_sidekick = BaseSidekick.find(1)
    sample_skill = BaseSkill.find(sample_sidekick.skill_id)

    puts "  Sample verification (#{sample_sidekick.name}):"

    [1, 3, 6, 9, 12, 15, 18, 20].each do |level|
      record = BaseSkillLevelUpEffect.find_by(skill_id: sample_sidekick.skill_id, level: level)
      if record
        puts "    L#{level.to_s.rjust(2, '0')}: #{record.effects.inspect}"
      else
        puts "    L#{level.to_s.rjust(2, '0')}: MISSING!"
      end
    end

    puts ""
    print "Confirm commit? Type 'YES' to permanently save: "
    final_confirm = STDIN.gets.chomp

    if final_confirm == 'YES'
      puts "✅ Changes committed to database"
    else
      puts "⚠️  Rolling back all changes..."
      raise ActiveRecord::Rollback
    end
  end

rescue ActiveRecord::Rollback
  puts "❌ Transaction rolled back. Database unchanged."
rescue => e
  puts "❌ ERROR: #{e.message}"
  puts e.backtrace.first(5).join("\n")
  puts "⚠️  Transaction automatically rolled back due to error."
end

puts ""
puts "Done."
