# FirstCharge Products - Required for IAP system
# Maps frontend tier selections to product IDs and prices

puts "Seeding FirstCharge Products..."

# Tier 3 (Low): $0.99
PurchaseProduct.find_or_create_by(product_id: 'hero_99') do |product|
  product.money = 0.99
  product.currency = 'USD'
end

# Tier 2 (Medium): $4.99
PurchaseProduct.find_or_create_by(product_id: 'hero_499') do |product|
  product.money = 4.99
  product.currency = 'USD'
end

# Tier 1 (High): $14.99
PurchaseProduct.find_or_create_by(product_id: 'hero_1499') do |product|
  product.money = 14.99
  product.currency = 'USD'
end

puts "FirstCharge Products seeding completed!"
puts "Total products: #{PurchaseProduct.count}"
