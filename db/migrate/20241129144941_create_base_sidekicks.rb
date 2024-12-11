class CreateBaseSidekicks < ActiveRecord::Migration[7.1]
  def change
    create_table :base_sidekicks do |t|
      t.string :name
      t.integer :skill_id
      t.text :character

      t.timestamps
    end
  end
end
