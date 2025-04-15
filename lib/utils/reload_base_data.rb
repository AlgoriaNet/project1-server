require 'roo'

class ReloadBaseData

  # def self.reload_base_sidekick
  #   excel = reload_excel_from_xlsx
  #   excel.default_sheet = "Sidekick"
  #   rows = excel.last_row
  #   headers = excel.row(1).map { |v| v.split("(")[0].strip }
  #   data = (2..rows).map do |i|
  #     headers.zip(excel.row i).to_h
  #   end
  #   data.each do |row|
  #     BaseSidekick.create({
  #                        name: row["name"],
  #                        description: row["description"],
  #                        skill_id:  BaseSkill.where(name: row["skill"]).first.id,
  #                        character: row["character"],
  #                        atk: row["atk"],
  #                        def: row["def"],
  #                        cri: row["cri"],
  #                        crt: row["crt"],
  #                        variety_damage: JSON.parse(row["variety_damage"]),
  #                      })
  #   end
  # end
  #
  # def self.reload_base_skill_level_up_effects
  #   excel = reload_excel_from_xlsx
  #   excel.default_sheet = "SkillLevelUp"
  #   rows = excel.last_row
  #   headers = excel.row(1).map { |v| v.split("(")[0].strip }
  #   data = (2..rows).map do |i|
  #     headers.zip(excel.row i).to_h
  #   end
  #   data = data.group_by { |k, v| [k["name"], k["level"]] }
  #   data.each do |k, v|
  #     row = {
  #       skill_id: BaseSkill.where(name: v[0]["name"]).first.id,
  #       level: v[0]["level"],
  #       weight: v[0]["weight"],
  #       depend_character: v[0]["depend_character"],
  #       max_count: v[0]["max_count"],
  #       description: v[0]["description"],
  #       effects: {}.tap{|v2| v.each { |v3|  v2[v3["effect"]] = v3["value"] } },
  #     }
  #     BaseSkillLevelUpEffect.create(row)
  #   end
  # end
  #
  # def self.reload_base_skill
  #   excel = reload_excel_from_xlsx
  #   excel.default_sheet = "Sidekick"
  #   rows = excel.last_row
  #   headers = excel.row(1).map { |v| v.split("(")[0].strip }
  #   data = (2..rows).map do |i|
  #     headers.zip(excel.row i).to_h
  #   end
  #   names = BaseSkill.column_names[1..-1]
  #
  #   data.each do |row|
  #     BaseSkill.create(Hash.tap { |h| names.each { |name| h[name] = row[name] } })
  #   end
  # end
  #
  # def self.reload_excel_from_xlsx
  #   path = "/Users/yangdegui/LivingConfig.xlsx"
  #
  #   Roo::Excelx.new(path)
  # end
end
