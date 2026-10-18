# frozen_string_literal: true

require "net/http"
require "uri"
require "json"
require "securerandom"

module Eza
  class Client
    DEFAULT_EMAIL_URL   = "https://email.eza.co.ke"
    DEFAULT_PAYEDGE_URL = "https://payedge.eza.co.ke"

    attr_reader :api_key, :email_key, :email_url, :payedge_url, :max_retries, :payedge, :emails

    def initialize(
      api_key: nil,
      email_key: nil,
      email_url: nil,
      payedge_url: nil,
      max_retries: 2,
      adapter: nil
    )
      @api_key = api_key || ENV["EZA_API_KEY"]
      @email_key = email_key || ENV["EZA_EMAIL_KEY"] || @api_key
      @email_url = (email_url || ENV["EZA_EMAIL_URL"] || DEFAULT_EMAIL_URL).chomp("/")
      @payedge_url = (payedge_url || ENV["EZA_PAYEDGE_URL"] || DEFAULT_PAYEDGE_URL).chomp("/")
      @max_retries = max_retries
      @adapter = adapter

      @payedge = PayEdge.new(self)
      @emails = Emails.new(self)
    end

    def request(method, url_str, service:, body: nil, idempotency_key: nil)
      auth_key = service == :email ? @email_key : @api_key
      if auth_key.nil? || auth_key.empty?
        service_name = service == :email ? "Email" : "PayEdge"
        env_var = service == :email ? "EZA_EMAIL_KEY or EZA_API_KEY" : "EZA_API_KEY"
        raise ConfigurationError, "No API key configured for #{service_name}. Pass api_key/email_key or set #{env_var}."
      end

      uri = URI.parse(url_str)
      idempotency_key ||= SecureRandom.uuid if method.to_sym == :post

      attempts = 0
      loop do
        attempts += 1
        headers = {
          "Authorization" => "Bearer #{auth_key}",
          "Content-Type" => "application/json",
          "Accept" => "application/json",
          "User-Agent" => "eza-ruby/#{VERSION}"
        }
        headers["Idempotency-Key"] = idempotency_key if idempotency_key

        begin
          res_status, res_headers, res_body = execute_http(method, uri, headers, body)
        rescue StandardError => e
          if attempts <= @max_retries
            sleep(0.1 * (2**(attempts - 1)))
            next
          end
          raise
        end

        # Handle 429 Rate Limit (honor Retry-After)
        if res_status == 429 && attempts <= @max_retries
          retry_after = res_headers["retry-after"]
          delay = retry_after ? [retry_after.to_f, 0.05].max : 0.2 * (2**(attempts - 1))
          sleep(delay)
          next
        end

        # Handle 503 / 504 Service Unavailable / Gateway Timeout
        if (res_status == 503 || res_status == 504) && attempts <= @max_retries
          sleep(0.1 * (2**(attempts - 1)))
          next
        end

        if res_status >= 200 && res_status < 300
          return res_body.empty? ? {} : JSON.parse(res_body)
        end

        raise Error.from_response(res_status, res_body, res_headers)
      end
    end

    private

    def execute_http(method, uri, headers, body)
      if @adapter
        return @adapter.call(method, uri, headers, body)
      end

      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = (uri.scheme == "https")
      http.open_timeout = 10
      http.read_timeout = 30

      req_class = case method.to_sym
                  when :post then Net::HTTP::Post
                  when :get  then Net::HTTP::Get
                  when :delete then Net::HTTP::Delete
                  else Net::HTTP::Get
                  end

      req = req_class.new(uri.request_uri)
      headers.each { |k, v| req[k] = v }
      req.body = JSON.generate(body) if body

      res = http.request(req)
      res_headers = {}
      res.each_header { |k, v| res_headers[k.downcase] = v }

      [res.code.to_i, res_headers, res.body || ""]
    end
  end
end
