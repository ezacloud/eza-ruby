# frozen_string_literal: true

require "uri"

module Eza
  class PayEdge
    def initialize(client)
      @client = client
    end

    def stk_push(phone:, amount_kes:, account_reference:, description: nil, config_id: nil, idempotency_key: nil)
      raise ArgumentError, "amount_kes must be an integer, got #{amount_kes.inspect}" unless amount_kes.is_a?(Integer)
      raise ArgumentError, "amount_kes must be at least 1 KES" if amount_kes < 1

      payload = {
        phone: phone,
        amount_kes: amount_kes,
        account_reference: account_reference
      }
      payload[:description] = description if description
      payload[:config_id] = config_id if config_id
      payload[:idempotency_key] = idempotency_key if idempotency_key

      @client.request(
        :post,
        "#{@client.payedge_url}/v1/stk-push",
        service: :payedge,
        body: payload,
        idempotency_key: idempotency_key
      )
    end

    def get_transaction(reference)
      escaped = URI.encode_www_form_component(reference)
      @client.request(
        :get,
        "#{@client.payedge_url}/v1/transactions/#{escaped}",
        service: :payedge
      )
    end
  end
end
