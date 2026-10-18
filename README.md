# Eza Cloud SDK for Ruby (`ezacloud-sdk`)

Official Ruby SDK for [Eza Cloud](https://eza.co.ke): PayEdge M-Pesa STK push, transactional emails, and cryptographically signed webhook verification.

Zero third-party runtime dependencies. Built entirely with the Ruby standard library (`net/http`, `openssl`, `json`, `securerandom`).

---

## Installation

Add to your `Gemfile`:

```ruby
gem "ezacloud-sdk"
```

Or install directly:

```bash
gem install ezacloud-sdk
```

---

## Usage

```ruby
require "eza"

# Auto-configures using EZA_API_KEY, EZA_EMAIL_KEY from ENV on Eza Cloud pods
eza = Eza.new(api_key: "eza_live_...")

# 1. Trigger an M-Pesa STK push
tx = eza.payedge.stk_push(
  phone: "254712345678",
  amount_kes: 1500,
  account_reference: "INV1024"
)
puts "Transaction pending: #{tx['checkout_request_id']}"

# 2. Send a transactional email
mail = eza.emails.send(
  from: "Shop <orders@mail.shop.co.ke>",
  to: "wanjiku@gmail.com",
  subject: "Your receipt",
  html: "<p>Thank you for your order!</p>"
)
puts "Email sent: #{mail['id']}"

# 3. Verify incoming webhook signatures
event = Eza.verify_webhook(
  request.raw_post,
  request.headers["Eza-Signature"],
  ENV["EZA_WEBHOOK_SECRET"]
)
puts "Verified event: #{event['type']}"
```
