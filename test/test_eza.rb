# frozen_string_literal: true

require "minitest/autorun"
require "json"
require_relative "../lib/eza"

class EzaTest < Minitest::Test
  def setup
    fixtures_path = File.expand_path("../conformance/fixtures.json", __dir__)
    @fixtures = JSON.parse(File.read(fixtures_path))
  end

  def test_webhook_conformance_valid
    wh = @fixtures["webhook"]
    now = Time.at(wh["timestamp"] + 30)

    event = Eza.verify_webhook(
      wh["body"],
      wh["header"],
      wh["secret"],
      tolerance: wh["tolerance_seconds"],
      now: now
    )

    assert_equal "evt_01", event["id"]
    assert_equal "payment.completed", event["type"]
    assert_equal 1500, event["data"]["amount_kes"]
  end

  def test_webhook_conformance_invalid_cases
    wh = @fixtures["webhook"]
    wh["invalid_cases"].each do |tc|
      now = Time.at(tc["now"])
      assert_raises(Eza::SignatureError, "Expected #{tc['name']} to fail") do
        Eza.verify_webhook(
          tc["body"],
          tc["header"],
          tc["secret"],
          tolerance: wh["tolerance_seconds"],
          now: now
        )
      end
    end
  end

  def test_payedge_stk_push_and_idempotency
    captured = {}
    adapter = lambda do |method, uri, headers, body|
      captured[:method] = method
      captured[:uri] = uri.to_s
      captured[:headers] = headers
      captured[:body] = body
      [201, {}, JSON.generate({ "id" => "tx_123", "checkout_request_id" => "ws_CO_123", "status" => "pending" })]
    end

    client = Eza::Client.new(api_key: "eza_live_testkey", adapter: adapter)
    res = client.payedge.stk_push(
      phone: "254712345678",
      amount_kes: 1500,
      account_reference: "INV1024"
    )

    assert_equal "tx_123", res["id"]
    assert_equal :post, captured[:method]
    assert_equal "Bearer eza_live_testkey", captured[:headers]["Authorization"]
    refute_nil captured[:headers]["Idempotency-Key"]
    assert_equal 1500, captured[:body][:amount_kes]
  end

  def test_payedge_refuses_decimals
    client = Eza::Client.new(api_key: "eza_live_testkey")
    assert_raises(ArgumentError) do
      client.payedge.stk_push(
        phone: "254712345678",
        amount_kes: 150.50,
        account_reference: "INV1024"
      )
    end
  end

  def test_email_send_and_retry
    attempts = 0
    adapter = lambda do |_method, _uri, _headers, _body|
      attempts += 1
      if attempts == 1
        [429, { "retry-after" => "0.01" }, JSON.generate({ "name" => "rate_limit_exceeded", "message" => "Slow down" })]
      else
        [200, {}, JSON.generate({ "id" => "mail_01928f3e" })]
      end
    end

    client = Eza::Client.new(email_key: "eza_mail_key", max_retries: 2, adapter: adapter)
    res = client.emails.send(
      from: "Shop <orders@mail.shop.co.ke>",
      to: "wanjiku@gmail.com",
      subject: "Your receipt",
      html: "<p>Paid KES 1,500</p>"
    )

    assert_equal "mail_01928f3e", res["id"]
    assert_equal 2, attempts
  end
end
