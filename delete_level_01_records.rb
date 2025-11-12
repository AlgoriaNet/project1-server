#!/usr/bin/env rails runner

puts "=" * 80
puts "DELETE L01 SKILL LEVEL RECORDS (FRONTEND HANDLES THESE)"
puts "=" * 80
puts ""

# STEP 1: INSPECT CURRENT STATE
puts "[STEP 1] Current database state:"
current_total = BaseSkillLevelUpEffect.count
level_01_count = BaseSkillLevelUpEffect.where(level: 1).count

puts "  Total records: #{current_total}"
puts "  Level 01 records: #{level_01_count}"
puts ""

puts "[STEP 2] Reason for deletion:"
puts "  Frontend displays L01 skill name directly from BaseSidekick"
puts "  Database L01 records are redundant and cause duplicate display"
puts ""

# STEP 3: PREVIEW
puts "[STEP 3] Preview - Sample L01 record to be deleted:"
sample = BaseSkillLevelUpEffect.find_by(level: 1)
if sample
  sidekick = BaseSidekick.find_by(skill_id: sample.skill_id)
  effects = sample.effects.is_a?(Hash) ? sample.effects : JSON.parse(sample.effects || '{}')
  puts "  Skill: #{sidekick.name if sidekick}"
  puts "  Level: #{sample.level}"
  puts "  Effects: #{effects.inspect}"
end
puts ""

# STEP 4: CONFIRMATION
puts "[STEP 4] Requesting confirmation..."
puts "This will PERMANENTLY DELETE all #{level_01_count} L01 records."
puts "Frontend will show skill names without database lookup."
puts ""
print "Type 'DELETE_L01' to proceed: "
confirmation = STDIN.gets.chomp

unless confirmation == 'DELETE_L01'
  puts "❌ Cancelled. No changes made."
  exit 0
end

puts ""
puts "[STEP 5] Starting transaction..."
puts ""

# STEP 5: BEGIN TRANSACTION AND DELETE
begin
  ApplicationRecord.transaction do
    deleted_count = BaseSkillLevelUpEffect.where(level: 1).delete_all
    puts "  Deleted #{deleted_count} L01 records"
    puts ""

    # VERIFY
    puts "[STEP 6] Verifying deletion..."
    final_total = BaseSkillLevelUpEffect.count
    final_level_01 = BaseSkillLevelUpEffect.where(level: 1).count

    puts "  Total records now: #{final_total}"
    puts "  L01 records remaining: #{final_level_01}"
    puts ""

    if final_level_01 == 0
      puts "  ✓ All L01 records deleted!"
    else
      puts "  ✗ ERROR: L01 records still exist!"
    end

    puts ""
    puts "[STEP 7] Remaining levels per sidekick:"
    sidekick = BaseSidekick.find(1)
    puts "  #{sidekick.name}:"
    BaseSkillLevelUpEffect.where(skill_id: sidekick.skill_id).order(:level).each do |e|
      effects = e.effects.is_a?(Hash) ? e.effects : JSON.parse(e.effects || '{}')
      puts "    L#{e.level.to_s.rjust(2, '0')}: #{effects.inspect}"
    end

    puts ""
    print "Confirm permanent commit? Type 'YES': "
    final_confirm = STDIN.gets.chomp

    if final_confirm == 'YES'
      puts "✅ Changes committed to database"
    else
      puts "⚠️  Rolling back deletion..."
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
