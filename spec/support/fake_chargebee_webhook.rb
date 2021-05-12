# frozen_string_literal: true

# spec/support/fake_chargebee_webhook.rb
class FakeChargebeeWebhook
  def initialize(fixture)
    @fixture = fixture
    load_fixture
  end

  attr_accessor(
    :body,
    :fixture,
    :headers
  )

  def fixture_path
    "#{Rails.root}/spec/fixtures/chargebee_webhooks/#{fixture}"
  end

  def load_fixture
    fixture_json = JSON.parse(File.read(fixture_path))

    @body = fixture_json.fetch('body')
    @headers = fixture_json.fetch('headers')

    return if Rails.configuration.chargebee_webhook_username.blank? || Rails.configuration.chargebee_webhook_password.blank?

    credentials = Base64.encode64("#{Rails.configuration.chargebee_webhook_username}:#{Rails.configuration.chargebee_webhook_password}").strip
    @headers['Authorization'] = "Basic #{credentials}"
  end
end
