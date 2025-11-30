class CreateDailyOfferTables < ActiveRecord::Migration[7.0]
  def change
    create_table :daily_offer_claims, if_not_exists: true do |t|
      t.references :player, null: false, foreign_key: true, comment: "Player who claimed the reward", index: false
      t.string :product_id, null: false, comment: "Daily offer product ID (daily_99, daily_199, daily_499)"
      t.date :claimed_date, null: false, comment: "Date when the reward was claimed (for daily reset)"
      t.datetime :claimed_at, null: false, comment: "When the reward was claimed"

      t.timestamps
    end

    # Unique index: one purchase per product per day per player
    add_index :daily_offer_claims, [:player_id, :product_id, :claimed_date],
              unique: true, name: "index_daily_offer_claims_unique", if_not_exists: true
    add_index :daily_offer_claims, :player_id, if_not_exists: true
  end
end
