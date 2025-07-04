# app/services/payment/google_validator.rb
# require 'google/apis/androidpublisher_v3'
# require 'googleauth'

module Payment
  class GoogleValidator
    def initialize(package_name, product_id, purchase_token)
      @package_name = package_name
      @product_id = product_id
      @purchase_token = purchase_token
    end

    def verify!
      # 使用服务账号JSON文件初始化
      authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: File.open(Rails.root.join('config', 'google-service-account.json')),
        scope: 'https://www.googleapis.com/auth/androidpublisher'
      )

      service = Google::Apis::AndroidpublisherV3::AndroidPublisherService.new
      service.authorization = authorizer

      begin
        result = service.get_purchase_product(
          @package_name,
          @product_id,
          @purchase_token
        )
        [true, result.to_h]
      rescue Google::Apis::Error => e
        [false, "Google验证失败: #{e.message}"]
      end
    end
  end
end
