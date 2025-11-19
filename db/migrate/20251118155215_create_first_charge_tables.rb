class CreateFirstChargeTables < ActiveRecord::Migration[7.1]
  def change
    # Table for first charge tier reward configurations
    create_table :first_charge_tier_rewards do |t|
      t.integer :tier, null: false, comment: "Tier level: 1, 2, or 3"
      t.integer :day, null: false, comment: "Day number: 1, 2, or 3"
      t.integer :sidekick_id, comment: "Sidekick ID (19 for Eleanor, only on day 1)"
      t.integer :diamond, default: 0, null: false, comment: "Diamond amount to reward"
      t.integer :rarekey_count, default: 0, null: false, comment: "Rare key count (day 1)"
      t.integer :epickey_count, default: 0, null: false, comment: "Epic key count (day 2)"
      t.integer :skillbook_count, default: 0, null: false, comment: "Skillbook count (day 3, for SKb_19_Eleanor)"
      t.integer :shard_count, default: 10, null: false, comment: "Shard count if sidekick already owned"

      t.timestamps
    end

    # Add unique index on tier + day combination
    add_index :first_charge_tier_rewards, [:tier, :day], unique: true

    # Table for tracking player claims
    create_table :first_charge_claims do |t|
      t.references :player, null: false, foreign_key: true, comment: "Player who claimed the reward"
      t.integer :tier, null: false, comment: "Tier level: 1, 2, or 3"
      t.integer :day, null: false, comment: "Day number: 1, 2, or 3"
      t.datetime :claimed_at, null: false, comment: "When the reward was claimed"

      t.timestamps
    end

    # Add unique index on player_id + tier + day combination (can only claim once per tier/day combo)
    add_index :first_charge_claims, [:player_id, :tier, :day], unique: true, name: 'index_first_charge_claims_unique'
  end
end
