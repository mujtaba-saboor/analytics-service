# frozen_string_literal: true

module ControllerSpecHelper
  def initialize_fake_chargebee_webhook(file_name)
    fake_chargebee_webhook = FakeChargebeeWebhook.new(file_name)
    [fake_chargebee_webhook.headers, fake_chargebee_webhook.body]
  end

  def chargebee_api_endpoint
    '/api/v1/chargebee_webhooks'
  end

  def create_fake_chargebee_event(file_name)
    @headers, @body = initialize_fake_chargebee_webhook(file_name)
    ChargebeeWebhook.create(event_name: @body['event_type'], event_id: @body['id'])
  end

  def make_webhook_request(file_name)
    @headers, @body = initialize_fake_chargebee_webhook(file_name)
    post(chargebee_api_endpoint, params: @body.to_json, headers: @headers)
  end
end
