class CreateBaseItems < ActiveRecord::Migration[7.1]
  def change
    create_table :base_items do |t|
      t.string :name
      t.text :description

      t.timestamps
    end
  end
end
