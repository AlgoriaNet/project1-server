#!/usr/bin/env rails runner

puts "=" * 80
puts "SAFE POPULATION OF SKILL LEVEL UP EFFECTS"
puts "=" * 80
puts ""

# STEP 1: INSPECT CURRENT STATE (READ-ONLY)
puts "[STEP 1] Inspecting current database state..."
current_count = BaseSkillLevelUpEffect.count
puts "  Current BaseSkillLevelUpEffect records: #{current_count}"
puts ""

# Check if any non-empty effects already exist
non_empty = BaseSkillLevelUpEffect.where("effects != '{}'").count
puts "  Records with non-empty effects: #{non_empty}"

empty_effects = BaseSkillLevelUpEffect.where("effects = '{}' OR effects IS NULL").count
puts "  Records with empty/null effects: #{empty_effects}"
puts ""

# STEP 2: DEFINE THE DATA STRUCTURE
puts "[STEP 2] Defining skill effects structure..."
effects_structure = {
  3 => { "ExtraDamageGain" => "0.20" },
  6 => { "ReduceCd" => "1.0" },
  9 => { "ExtraDamageGain" => "0.35" },
  12 => { "AddDuration" => "2.0" },
  15 => { "AddReleaseCount" => "1" },
  18 => { "ReduceCd" => "2.0" },
  20 => { "ExtraDamageGain" => "0.50" }
}

puts "  Effects levels to populate: #{effects_structure.keys.sort.join(', ')}"
puts "  Total effect types: #{effects_structure.size}"
puts ""

# STEP 3: COUNT HOW MANY RECORDS NEED UPDATING
puts "[STEP 3] Planning data updates..."
all_sidekicks = BaseSidekick.all
puts "  Total sidekicks in system: #{all_sidekicks.count}"

records_to_update = 0
all_sidekicks.each do |sidekick|
  effects_structure.keys.each do |level|
    existing = BaseSkillLevelUpEffect.find_by(skill_id: sidekick.skill_id, level: level)
    if existing && (existing.effects == '{}' || existing.effects.nil?)
      records_to_update += 1
    end
  end
end

puts "  Records to update (empty effects only): #{records_to_update}"
puts "  Records to create (if missing): #{(all_sidekicks.count * effects_structure.size) - current_count}"
puts ""

# STEP 4: PREVIEW THE CHANGES (NO DATABASE WRITES YET)
puts "[STEP 4] Previewing sample data to be inserted..."
sample_sidekick = BaseSidekick.first
effects_structure.each do |level, effects|
  puts "  Level #{level}: #{effects.inspect}"
end
puts ""

# STEP 5: ASK FOR CONFIRMATION
puts "[STEP 5] Requesting confirmation before proceeding..."
puts "This script will:"
puts "  1. Update empty effects records with proper game mechanics data"
puts "  2. Create any missing level records"
puts "  3. Keep all existing non-empty effects unchanged"
puts ""
puts "NO RECORDS WILL BE DELETED OR MODIFIED EXCEPT EMPTY EFFECTS FIELDS"
puts ""
print "Type 'CONFIRM' to proceed: "
confirmation = STDIN.gets.chomp

unless confirmation == 'CONFIRM'
  puts "❌ Cancelled by user. No changes made."
  exit 0
end

puts ""
puts "[STEP 6] Starting transaction (can be rolled back)..."
puts ""

# STEP 6: BEGIN TRANSACTION
begin
  ApplicationRecord.transaction do
    updated_count = 0
    created_count = 0

    all_sidekicks.each do |sidekick|
      effects_structure.each do |level, effects|
        record = BaseSkillLevelUpEffect.find_by(skill_id: sidekick.skill_id, level: level)

        if record
          # Update if empty
          if record.effects == '{}' || record.effects.nil?
            puts "  [UPDATE] Skill #{sidekick.skill_id} (#{sidekick.name}), Level #{level}: #{effects.inspect}"
            record.update!(effects: effects.to_json)
            updated_count += 1
          end
        else
          # Create if missing
          puts "  [CREATE] Skill #{sidekick.skill_id} (#{sidekick.name}), Level #{level}: #{effects.inspect}"
          BaseSkillLevelUpEffect.create!(
            skill_id: sidekick.skill_id,
            level: level,
            effects: effects.to_json
          )
          created_count += 1
        end
      end
    end

    puts ""
    puts "=" * 80
    puts "TRANSACTION SUMMARY"
    puts "=" * 80
    puts "  Records updated: #{updated_count}"
    puts "  Records created: #{created_count}"
    puts "  Total changed: #{updated_count + created_count}"
    puts ""

    # STEP 7: VERIFY THE CHANGES (BEFORE COMMIT)
    puts "[STEP 7] Verifying data integrity within transaction..."

    verify_empty = BaseSkillLevelUpEffect.where("effects = '{}' OR effects IS NULL").count
    verify_non_empty = BaseSkillLevelUpEffect.where("effects != '{}'").count

    puts "  Records with empty effects: #{verify_empty}"
    puts "  Records with data: #{verify_non_empty}"
    puts "  Total records: #{BaseSkillLevelUpEffect.count}"
    puts ""

    # Check sample data
    sample = BaseSkillLevelUpEffect.find_by(skill_id: 1, level: 3)
    if sample
      puts "  Sample record (Skill 1, Level 3):"
      puts "    Effects JSON: #{sample.effects.inspect}"
      parsed = JSON.parse(sample.effects)
      puts "    Parsed: #{parsed.inspect}"
      puts "    Valid format: ✓"
    end

    puts ""
    print "Confirm commit? Type 'YES' to permanently save changes: "
    final_confirm = STDIN.gets.chomp

    if final_confirm == 'YES'
      # Transaction will auto-commit when block ends
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
  puts e.backtrace.join("\n")
  puts "⚠️  Transaction automatically rolled back due to error."
end

puts ""
puts "Done."
