class AddMonthlyAndWeeklyCardExpiryToPlayer < ActiveRecord::Migration[7.1]
  def change
    add_column :players, :monthly_card_expiry, :string
    add_column :players, :weekly_card_expiry, :string
  end
end
