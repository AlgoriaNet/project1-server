class AddSigninColumnsToPlayers < ActiveRecord::Migration[7.1]
  def change
    add_column :players, :signin_cycle_number, :integer, default: 1, null: false, comment: "Current sign-in cycle (1, 2, 3...)"
    add_column :players, :signin_first_date, :date, comment: "First day player started sign-in system"
    add_column :players, :signin_last_claim_date, :date, comment: "Last date player claimed daily sign-in"
    add_column :players, :signin_consecutive_days, :integer, default: 0, null: false, comment: "Consecutive days signed in (resets if day missed)"
  end
end
