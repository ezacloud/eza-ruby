# frozen_string_literal: true

require "openssl"
require "json"

module Eza
  module Webhook
    DEFAULT_TOLERANCE = 300

    module_function

    def verify(raw_body, signature_header, secret, tolerance: DEFAULT_TOLERANCE, now: nil)
      raise SignatureError, "Missing raw body or signature header" if raw_body.nil? || signature_header.nil?
      raise SignatureError, "Missing webhook secret" if secret.nil? || secret.empty?

      timestamp = nil
      signature = nil

      signature_header.to_s.split(",").each do |part|
        key, value = part.strip.split("=", 2)
        case key
        when "t"
          timestamp = Integer(value, 10) rescue nil
        when "v1"
          signature = value
        end
      end

      raise SignatureError, "Malformed signature header: missing timestamp or signature" if timestamp.nil? || signature.nil?

      current_time = now ? now.to_i : Time.now.to_i
      if (current_time - timestamp).abs > tolerance
        raise SignatureError, "Webhook timestamp outside tolerance zone (#{tolerance}s)"
      end

      signed_payload = "t.#{timestamp}.#{raw_body}"
      computed = OpenSSL::HMAC.hexdigest("SHA256", secret, signed_payload)

      unless secure_compare(computed, signature)
        raise SignatureError, "Webhook signature mismatch"
      end

      JSON.parse(raw_body)
    end

    def secure_compare(a, b)
      return false unless a.is_a?(String) && b.is_a?(String) && a.bytesize == b.bytesize

      if OpenSSL.respond_to?(:secure_compare)
        OpenSSL.secure_compare(a, b)
      else
        res = 0
        a.bytes.zip(b.bytes) { |x, y| res |= x ^ y }
        res.zero?
      end
    end
  end
end
