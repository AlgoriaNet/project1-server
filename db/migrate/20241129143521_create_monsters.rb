class CreateMonsters < ActiveRecord::Migration[7.1]
  def change
    create_table :monsters do |t|
      t.string :name
      t.integer :range
      t.string :type
      t.json :character
      t.timestamps
    end
  end
end
