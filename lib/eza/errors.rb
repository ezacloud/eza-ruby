# frozen_string_literal: true

module Eza
  class Error < StandardError
    attr_reader :status, :code, :request_id, :fields

    def self.from_response(status, body, headers = {})
      data = begin
        JSON.parse(body)
      rescue StandardError
        {}
      end

      request_id = headers["eza-request-id"] || headers["x-request-id"] || data["request_id"]
      code = data["code"] || data["name"]
      message = data["message"] || data["detail"] || "HTTP #{status}"
      fields = data["fields"] || data["errors"]

      new(message, status: status, code: code, request_id: request_id, fields: fields)
    end

    def initialize(message, status: nil, code: nil, request_id: nil, fields: nil)
      @status = status
      @code = code
      @request_id = request_id
      @fields = fields
      super(build_message(message))
    end

    private

    def build_message(base_message)
      parts = []
      parts << "[#{@code}]" if @code
      parts << base_message
      parts << "(status #{@status})" if @status
      parts << "(request_id: #{@request_id})" if @request_id
      parts.join(" ")
    end
  end

  class SignatureError < StandardError; end
  class ConfigurationError < StandardError; end
end
