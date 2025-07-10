class AddGoldCostToBaseSkillLevelUpEffects < ActiveRecord::Migration[7.1]
  def change
    add_column :base_skill_level_up_effects, :gold_cost, :integer
  end
end
