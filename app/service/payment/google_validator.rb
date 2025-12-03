# app/services/payment/google_validator.rb
begin
  require 'google/apis/androidpublisher_v3'
  require 'googleauth'
rescue LoadError
  Rails.logger.warn "Google API gems not installed. Install google-apis-androidpublisher_v3 and googleauth gems."
end

module Payment
  class GoogleValidator
    def initialize(package_name, product_id, purchase_token)
      @package_name = package_name
      @product_id = product_id
      @purchase_token = purchase_token
    end

    def verify!
      # Check if Google gems are available
      unless defined?(Google::Auth::ServiceAccountCredentials)
        raise ArgumentError, "Google API libraries not available. Please install google-apis-androidpublisher_v3 and googleauth gems."
      end

      # Load credentials from environment variable or local file
      credentials_json = ENV['GOOGLE_SERVICE_ACCOUNT']

      # Fallback to local file for development (if env var not set)
      if credentials_json.blank?
        config_file = Rails.root.join('config', 'google-service-account.json')
        if File.exist?(config_file)
          credentials_json = File.read(config_file)
        else
          raise ArgumentError, "Google service account credentials not found. Set GOOGLE_SERVICE_ACCOUNT env var or create config/google-service-account.json"
        end
      end

      # Parse credentials and initialize authorizer
      require 'stringio'
      authorizer = Google::Auth::ServiceAccountCredentials.make_creds(
        json_key_io: StringIO.new(credentials_json),
        scope: 'https://www.googleapis.com/auth/androidpublisher'
      )

      service = Google::Apis::AndroidpublisherV3::AndroidPublisherService.new
      service.authorization = authorizer

      begin
        token_preview = @purchase_token.to_s.length > 20 ? @purchase_token[0..20] + "..." : @purchase_token.to_s
        Rails.logger.info "[GoogleValidator] Validating purchase: package=#{@package_name}, product=#{@product_id}, token=#{token_preview}, token_class=#{@purchase_token.class}, token_nil=#{@purchase_token.nil?}"

        result = service.get_purchase_product(
          @package_name,
          @product_id,
          @purchase_token
        )
        Rails.logger.info "[GoogleValidator] Google Play response: purchase_state=#{result.purchase_state}"

        # Validate purchase state - must be purchased (1) or pending (0)
        # Google Play returns: 0=pending, 1=purchased, 2=canceled
        purchase_state = result.purchase_state.to_i
        unless purchase_state == 1 || purchase_state == 0
          raise ArgumentError, "Google purchase state is invalid: #{purchase_state}"
        end
        [true, result.to_h]
      rescue Google::Apis::Error => e
        Rails.logger.error "[GoogleValidator] Google API error: #{e.message}\nRequest: package=#{@package_name}, product=#{@product_id}"
        raise ArgumentError, "Google验证失败: #{e.message}"
      rescue ArgumentError => e
        raise ArgumentError, e.message
      end
    end
  end
end
