#!/usr/bin/env rails runner

puts "=" * 80
puts "INSPECTING BASE_SKILLS TABLE"
puts "=" * 80
puts ""

puts "[All 20 Base Skills in Current US Database]"
puts ""

BaseSkill.order(:id).each do |skill|
  puts "ID #{skill.id.to_s.rjust(2)}: #{skill.name.ljust(30)} | cd: #{skill.cd.to_s.ljust(5)} | duration: #{skill.duration.to_s.ljust(5)} | damage_ratio: #{skill.damage_ratio.to_s.ljust(5)}"
end

puts ""
puts "=" * 80
puts "LOOKING FOR 'Sacred Slash' OR 'Dummy' SKILLS"
puts "=" * 80
puts ""

dummy_count = BaseSkill.where("name LIKE ?", "%Dummy%").count
sacred_slash = BaseSkill.where("name LIKE ?", "%Sacred%").count

puts "Skills with 'Dummy' in name: #{dummy_count}"
puts "Skills with 'Sacred' in name: #{sacred_slash}"
puts ""

if sacred_slash == 0
  puts "❌ 'Sacred Slash' NOT FOUND in BaseSkill table"
end

if dummy_count > 0
  puts "⚠️  WARNING: Found #{dummy_count} dummy skills still in database"
  puts ""
  puts "Dummy skills:"
  BaseSkill.where("name LIKE ?", "%Dummy%").each do |skill|
    puts "  ID #{skill.id}: #{skill.name}"
  end
end
