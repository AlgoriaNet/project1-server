class RemoveUnusedFieldsFromBaseSkillLevelUpEffects < ActiveRecord::Migration[7.1]
  def change
    # Remove unused fields that frontend no longer needs
    remove_column :base_skill_level_up_effects, :weight, :integer
    remove_column :base_skill_level_up_effects, :depend_character, :string
    remove_column :base_skill_level_up_effects, :max_count, :integer
    remove_column :base_skill_level_up_effects, :description, :text
    remove_column :base_skill_level_up_effects, :gold_cost, :integer
    remove_column :base_skill_level_up_effects, :effect_name, :string
  end
end
