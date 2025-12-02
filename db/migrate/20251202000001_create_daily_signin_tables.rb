class CreateDailySigninTables < ActiveRecord::Migration[7.1]
  def change
    # Table for daily sign-in reward configurations (30 days)
    create_table :daily_signin_rewards do |t|
      t.integer :day_number, null: false, comment: "Day in cycle: 1-30"
      t.string :reward_type, null: false, comment: "Type: gold_coin, skillbooks, milestone"
      t.integer :gold_coin, default: 0, null: false, comment: "Gold coin amount (odd days: 200)"
      t.integer :skillbook_count, default: 0, null: false, comment: "Total skillbooks (even days: 50)"
      t.integer :diamond, default: 0, null: false, comment: "Diamond amount (milestones)"
      t.integer :epic_key, default: 0, null: false, comment: "Epic key count (milestones)"
      t.integer :hero_key, default: 0, null: false, comment: "Hero key count (day 30)"
      t.integer :rare_key, default: 0, null: false, comment: "Rare key count (day 30)"

      t.timestamps
    end

    # Add unique index on day_number
    add_index :daily_signin_rewards, :day_number, unique: true

    # Table for tracking player daily sign-in claims
    create_table :daily_signin_claims do |t|
      t.references :player, null: false, foreign_key: true, comment: "Player who claimed"
      t.integer :cycle_number, null: false, comment: "Cycle number (1, 2, 3...)"
      t.integer :day_number, null: false, comment: "Day in cycle: 1-30"
      t.boolean :reclaimed, default: false, null: false, comment: "Was this day reclaimed for 20 diamonds?"
      t.datetime :claimed_at, null: false, comment: "When the day was claimed"
      t.text :rewards_json, comment: "JSON of rewards given (for skillbook distribution)"

      t.timestamps
    end

    # Add unique index on player_id + cycle_number + day_number
    add_index :daily_signin_claims, [:player_id, :cycle_number, :day_number],
              unique: true, name: 'index_daily_signin_claims_unique'

    # Table for tracking milestone claims
    create_table :daily_signin_milestones do |t|
      t.references :player, null: false, foreign_key: true, comment: "Player who claimed"
      t.integer :cycle_number, null: false, comment: "Cycle number (1, 2, 3...)"
      t.integer :milestone_day, null: false, comment: "Milestone day: 7, 14, 21, or 30"
      t.datetime :claimed_at, null: false, comment: "When the milestone was claimed"

      t.timestamps
    end

    # Add unique index on player_id + cycle_number + milestone_day
    add_index :daily_signin_milestones, [:player_id, :cycle_number, :milestone_day],
              unique: true, name: 'index_daily_signin_milestones_unique'
  end
end
