# frozen_string_literal: true

require_relative "lib/eza/version"

Gem::Specification.new do |spec|
  spec.name          = "ezacloud-sdk"
  spec.version       = Eza::VERSION
  spec.authors       = ["Eza Cloud"]
  spec.email         = ["support@eza.co.ke"]

  spec.summary       = "Official Ruby SDK for Eza Cloud (PayEdge M-Pesa, Transactional Email, Webhooks)"
  spec.description   = "Zero-dependency Ruby client for Eza Cloud. Initiate M-Pesa STK pushes, send transactional emails, and verify cryptographically signed webhooks."
  spec.homepage      = "https://eza.co.ke/docs"
  spec.license       = "MIT"
  spec.required_ruby_version = ">= 3.1.0"

  spec.metadata["homepage_uri"] = spec.homepage
  spec.metadata["source_code_uri"] = "https://github.com/ezacloud/eza/tree/main/sdks/ruby"
  spec.metadata["documentation_uri"] = "https://eza.co.ke/docs"

  spec.files = Dir["lib/**/*.rb", "README.md", "LICENSE"]
  spec.require_paths = ["lib"]
end
