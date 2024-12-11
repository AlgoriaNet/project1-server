class CreateMainStages < ActiveRecord::Migration[7.1]
  def change
    create_table :main_stages do |t|
      t.integer :level
      t.string :name
      t.json :monsters
      t.json :upgrade_required_experience
      t.json :first_award
      t.json :win_reward
      t.json :lose_reward

      t.timestamps
    end
  end
end
