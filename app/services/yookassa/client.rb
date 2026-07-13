require "net/http"
require "uri"

module Yookassa
  class Client
    API_BASE = "https://api.yookassa.ru/v3".freeze

    class Error < StandardError
      attr_reader :status, :body

      def initialize(message, status: nil, body: nil)
        super(message)
        @status = status
        @body = body
      end
    end

    def create_payment(idempotence_key:, body:)
      post("/payments", body: body, idempotence_key: idempotence_key)
    end

    def fetch_payment(payment_id)
      get("/payments/#{payment_id}")
    end

    private

    def get(path)
      request(:get, path)
    end

    def post(path, body:, idempotence_key:)
      request(:post, path, body: body, idempotence_key: idempotence_key)
    end

    def request(method, path, body: nil, idempotence_key: nil)
      uri = URI("#{API_BASE}#{path}")
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true
      http.open_timeout = 10
      http.read_timeout = 30

      req = build_request(method, uri, body:, idempotence_key:)
      response = http.request(req)
      parsed = parse_json(response.body)

      return parsed if response.is_a?(Net::HTTPSuccess)

      raise Error.new(
        "YooKassa API error (#{response.code})",
        status: response.code.to_i,
        body: parsed
      )
    end

    def build_request(method, uri, body:, idempotence_key:)
      klass = method == :get ? Net::HTTP::Get : Net::HTTP::Post
      req = klass.new(uri)
      req.basic_auth(Configuration.shop_id, Configuration.secret_key)
      req["Content-Type"] = "application/json"
      req["Idempotence-Key"] = idempotence_key if idempotence_key.present?
      req.body = body.to_json if body.present?
      req
    end

    def parse_json(raw)
      return {} if raw.blank?

      JSON.parse(raw)
    rescue JSON::ParserError
      { "raw" => raw }
    end
  end
end
