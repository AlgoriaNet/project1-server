require 'net/http'
require 'json'

module Payment
  class AppleValidator
    PRODUCTION_URL = 'https://buy.itunes.apple.com/verifyReceipt'
    SANDBOX_URL = 'https://sandbox.itunes.apple.com/verifyReceipt'

    def initialize(receipt_data, sandbox: false)
      @receipt_data = receipt_data
      @url = sandbox ? SANDBOX_URL : PRODUCTION_URL
    end

    def verify!
      uri = URI(@url)
      request = Net::HTTP::Post.new(uri)
      request.content_type = 'application/json'
      request.body = { 'receipt-data' => @receipt_data }.to_json

      response = Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
        http.request(request)
      end

      if response.try(&:code).to_s == '200'
        result = JSON.parse(response.body)
        result['status'] == 0 ? [true, result] : [false, "苹果验证失败(状态码: #{result['status']})"]
      else
        [false, "苹果服务器请求失败"]
      end
    rescue => e
      [false, "验证异常: #{e.message}"]
    end
  end
end
