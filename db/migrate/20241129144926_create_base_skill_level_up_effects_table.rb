class CreateBaseSkillLevelUpEffectsTable < ActiveRecord::Migration[7.1]
  def change
    create_table :base_skill_level_up_effects do |t|
      t.bigint :skill_id, null: false
      t.string :effect_name, limit: 25, comment: "效果名称"
      t.integer :level, null: false, comment: "等级"
      t.text :effects, null: false, comment: "效果"
      t.integer :weight, default: 10, comment: "3选1权重"
      t.string :depend_character, limit: 225, comment: "依赖特性"
      t.integer :max_count, default: 1, null: false, comment: "3选1最大出现次数"
      t.text :description

      t.timestamps

    end
    add_foreign_key :base_skill_level_up_effects, :base_skills, column: :skill_id
  end
end
