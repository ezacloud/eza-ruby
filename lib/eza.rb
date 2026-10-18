# frozen_string_literal: true

require_relative "eza/version"
require_relative "eza/errors"
require_relative "eza/webhook"
require_relative "eza/payedge"
require_relative "eza/emails"
require_relative "eza/client"

module Eza
  class << self
    def new(**options)
      Client.new(**options)
    end

    def verify_webhook(...)
      Webhook.verify(...)
    end
  end
end
