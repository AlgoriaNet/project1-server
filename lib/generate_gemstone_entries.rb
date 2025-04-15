class GenerateGemstoneEntries

  def self.generate
    [{name: "Hp", init: 20, step: 20, min_level: 1},
     {name: "SufferedDamage", init: 1, step: 0.5, min_level: 1},
     {name: "Atk", init: 10, step: 10, min_level: 1},
     {name: "Ctr", init: 1, step: 1, min_level: 1},
     {name: "Cti", init: 3, step: 2, min_level: 1},
     {name: "Mechanical", init: 3, step: 2, min_level: 1},
     {name: "Light", init: 3, step: 2, min_level: 1},
     {name: "Fire", init: 3, step: 2, min_level: 1},
     {name: "Ice", init: 3, step: 2, min_level: 1},
     {name: "Wind", init: 3, step: 2, min_level: 1},
     {name: "Physics", init: 3, step: 2, min_level: 1},
     {name: "Darkly", init: 3, step: 2, min_level: 1},
     {name: "Heal", init: 1, step: 1, min_level: 5},
     {name: "Damage", init: 3, step: 2, min_level: 5},
     {name: "Cd", init: 2, step: 1, min_level: 5},
     {name: "Penetrat", init: 1, step: 1, min_level: 5}].each do |gemstone|

      ge = GemstoneEntry.find_or_create_by!(name: gemstone[:name])
      ge.description = gemstone[:name]
      (gemstone[:min_level]..Gemstone::MAX_LEVEL).each do |level|
        ge.send("level_#{level}_value=", gemstone[:init] + (level - gemstone[:min_level]) * gemstone[:step])
      end
      puts ge.as_json
      ge.save!
    end
  end
end
