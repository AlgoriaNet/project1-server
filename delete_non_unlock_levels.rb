#!/usr/bin/env rails runner

puts "=" * 80
puts "DELETE NON-UNLOCK SKILL LEVELS FROM DATABASE"
puts "=" * 80
puts ""

# STEP 1: INSPECT CURRENT STATE
puts "[STEP 1] Current database state:"
current_total = BaseSkillLevelUpEffect.count
puts "  Total records: #{current_total}"
puts ""

# Define unlock levels - only these should exist
unlock_levels = [1, 3, 6, 9, 12, 15, 18, 20]
non_unlock_levels = (1..20).to_a - unlock_levels

puts "[STEP 2] Unlock levels (to KEEP): #{unlock_levels.join(', ')}"
puts "[STEP 3] Non-unlock levels (to DELETE): #{non_unlock_levels.join(', ')}"
puts ""

# STEP 4: COUNT WHAT WILL BE DELETED
records_to_delete = BaseSkillLevelUpEffect.where(level: non_unlock_levels).count
records_to_keep = BaseSkillLevelUpEffect.where(level: unlock_levels).count

puts "[STEP 4] Records to delete: #{records_to_delete}"
puts "[STEP 5] Records to keep: #{records_to_keep}"
puts "[STEP 6] Final total should be: #{records_to_keep}"
puts ""

# STEP 5: SHOW PREVIEW
puts "[STEP 7] Preview - Sample sidekick before deletion:"
sidekick = BaseSidekick.find(1)
puts "  #{sidekick.name}:"
BaseSkillLevelUpEffect.where(skill_id: sidekick.skill_id).order(:level).each do |e|
  puts "    L#{e.level.to_s.rjust(2, '0')}"
end
puts ""

# STEP 6: CONFIRMATION
puts "[STEP 8] Requesting confirmation..."
puts "This will PERMANENTLY DELETE #{records_to_delete} records."
puts "Cannot be undone - must have database backup!"
puts ""
print "Type 'DELETE' to proceed: "
confirmation = STDIN.gets.chomp

unless confirmation == 'DELETE'
  puts "❌ Cancelled. No changes made."
  exit 0
end

puts ""
puts "[STEP 9] Starting transaction..."
puts ""

# STEP 7: BEGIN TRANSACTION AND DELETE
begin
  ApplicationRecord.transaction do
    deleted_count = 0

    non_unlock_levels.each do |level|
      count = BaseSkillLevelUpEffect.where(level: level).delete_all
      deleted_count += count
      puts "  Deleted #{count} records at Level #{level.to_s.rjust(2, '0')}"
    end

    puts ""
    puts "=" * 80
    puts "DELETION SUMMARY"
    puts "=" * 80
    puts "  Records deleted: #{deleted_count}"
    puts ""

    # VERIFY
    puts "[STEP 10] Verifying data after deletion..."
    final_total = BaseSkillLevelUpEffect.count
    puts "  Total records now: #{final_total}"
    puts "  Expected: #{records_to_keep}"

    if final_total == records_to_keep
      puts "  ✓ Verification passed!"
    else
      puts "  ✗ ERROR: Count mismatch!"
    end

    puts ""

    # Show sample after deletion
    puts "[STEP 11] Sample sidekick after deletion:"
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
      puts "⚠️  Rolling back all deletions..."
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
