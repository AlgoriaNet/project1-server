class CreatePurchaseProducts < ActiveRecord::Migration[7.1]
  def change
    create_table :purchase_products do |t|
      t.string :product_id, null: false, index: { unique: true }
      t.decimal :money, scale: 2, precision: 10, null: false
      t.string :currency, default: 'USD'
      t.text :description
      t.json :reward_items

      t.timestamps
    end
  end
end
