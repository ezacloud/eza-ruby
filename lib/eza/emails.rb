# frozen_string_literal: true

require "base64"
require "uri"

module Eza
  class Emails
    def initialize(client)
      @client = client
    end

    def send(from:, to:, subject:, text: nil, html: nil, cc: nil, bcc: nil, reply_to: nil, attachments: nil, idempotency_key: nil)
      raise ArgumentError, "Must provide text or html content" if text.nil? && html.nil?

      recipients = Array(to)
      payload = {
        from: from,
        to: recipients,
        subject: subject
      }
      payload[:text] = text if text
      payload[:html] = html if html
      payload[:cc] = Array(cc) if cc
      payload[:bcc] = Array(bcc) if bcc
      payload[:reply_to] = reply_to if reply_to

      if attachments && !attachments.empty?
        payload[:attachments] = attachments.map do |att|
          content = att[:content]
          encoded = if content.is_a?(String) && !att[:already_base64]
                      Base64.strict_encode64(content)
                    else
                      content
                    end
          {
            filename: att[:filename] || att["filename"],
            content: encoded
          }
        end
      end

      @client.request(
        :post,
        "#{@client.email_url}/emails",
        service: :email,
        body: payload,
        idempotency_key: idempotency_key
      )
    end

    def get(id)
      escaped = URI.encode_www_form_component(id)
      @client.request(
        :get,
        "#{@client.email_url}/emails/#{escaped}",
        service: :email
      )
    end
  end
end
