# app/services/payment/signature_validator.rb
require 'digest'

module Payment
  class SignatureValidator
    def initialize(params)
      @params = params
    end


    def validate!
      received_sign = @params.delete('sign')
      raise ArgumentError, ErrorMsg::SIGNATURE_REQUIRED if received_sign.blank?

      sign_str = @params.sort.map { |k, v| "#{k}=#{v}" }.join('&') + Rails.application.credentials[:secret_key_base]

      calculated_sign = Digest::MD5.hexdigest(sign_str)
      raise ArgumentError, ErrorMsg::SIGNATURE_NOT_MATCH if calculated_sign != received_sign
    end
  end
end
