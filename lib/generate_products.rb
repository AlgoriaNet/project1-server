class GenerateProducts

  def self.generate
    PurchaseProduct.destroy_all
    CsvConfig.load_products.each do |product|
      PurchaseProduct.create(product)
    end
  end
end
