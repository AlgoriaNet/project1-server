# Daily Offer Products - Required for IAP system
# Daily offers reset each day and allow one purchase per tier per day

puts "Seeding Daily Offer Products..."

# Daily Offer Tier 3 (Low): $0.99
# Rewards: 60 Diamond, 500 Gold, 10 Rare Keys
PurchaseProduct.find_or_create_by(product_id: 'daily_99') do |product|
  product.money = 0.99
  product.currency = 'USD'
  product.description = 'Daily Offer - Elite Pack'
end

# Daily Offer Tier 2 (Medium): $1.99
# Rewards: 120 Diamond, 500 Gold, 5 Rare Keys, 5 Epic Keys
PurchaseProduct.find_or_create_by(product_id: 'daily_199') do |product|
  product.money = 1.99
  product.currency = 'USD'
  product.description = 'Daily Offer - Deluxe Pack'
end

# Daily Offer Tier 1 (High): $4.99
# Rewards: 330 Diamond, 500 Gold, 2 Rare Keys, 3 Epic Keys, 5 Hero Keys
PurchaseProduct.find_or_create_by(product_id: 'daily_499') do |product|
  product.money = 4.99
  product.currency = 'USD'
  product.description = 'Daily Offer - Premium Pack'
end

puts "Daily Offer Products seeding completed!"
puts "Total products: #{PurchaseProduct.count}"
