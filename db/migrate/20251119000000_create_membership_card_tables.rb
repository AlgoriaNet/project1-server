class CreateMembershipCardTables < ActiveRecord::Migration[7.1]
  def change
    # Table for membership card reward configurations
    # Stores reward values for weekly and monthly cards
    create_table :membership_card_rewards do |t|
      t.string :card_type, null: false, comment: "Card type: 'weekly' or 'monthly'"
      t.integer :diamond_one_time, default: 0, null: false, comment: "One-time diamond reward upon purchase"
      t.integer :diamond_per_day, default: 0, null: false, comment: "Daily diamond reward (monthly only)"
      t.integer :gold_per_day, default: 0, null: false, comment: "Daily gold reward"
      t.integer :rarekey_per_day, default: 0, null: false, comment: "Daily rare key reward (weekly only)"
      t.integer :epickey_per_day, default: 0, null: false, comment: "Daily epic key reward (weekly only)"
      t.integer :stamina_per_day, default: 0, null: false, comment: "Daily stamina reward (monthly only, displayed as 'Power')"

      t.timestamps
    end

    # Add unique index on card_type to ensure only one config per card type
    add_index :membership_card_rewards, :card_type, unique: true

    # Table for tracking player membership card claims (daily rewards)
    create_table :membership_card_claims do |t|
      t.references :player, null: false, foreign_key: true, comment: "Player who claimed the reward"
      t.string :card_type, null: false, comment: "Card type: 'weekly' or 'monthly'"
      t.integer :day_number, null: false, comment: "Day number of the card duration"
      t.datetime :claimed_at, null: false, comment: "When the reward was claimed"

      t.timestamps
    end

    # Add unique index on player_id + card_type + day_number combination
    # Prevents duplicate claims for same card/day combination
    add_index :membership_card_claims, [:player_id, :card_type, :day_number], unique: true, name: 'index_membership_card_claims_unique'
  end
end
