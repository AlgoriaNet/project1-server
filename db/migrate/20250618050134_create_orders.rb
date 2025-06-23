class CreateOrders < ActiveRecord::Migration[7.1]
  def change
    create_table :orders do |t|
      t.references :player, null: false, foreign_key: true
      t.string :order_id, null: false, index: { unique: true }
      t.string :product_id, null: false
      t.string :platform_order_id, null: true, index: { unique: true }
      t.string :platform, null: false # 如: apple, google, wechat, alipay
      t.boolean :is_sandbox, default: false
      t.decimal :money, scale: 2,precision:10, null: false # 以分为单位存储
      t.string :currency, null: false, default: 'CNY'
      t.datetime :pay_time
      t.datetime :deliver_time
      t.string :status, null: false, default: 'pending' # pending, paid, delivered, failed, refunded
      t.timestamps
    end

    add_index :orders, [:player_id, :platform, :status]
  end
end
