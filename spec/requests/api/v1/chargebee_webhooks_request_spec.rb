# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Api::V1::ChargebeeWebhooks', type: :request do

  describe 'POST /api/v1/chargebee_webhooks subscription_created' do
    before :all do
      VCR.use_cassette('first_subscription_created_request') do
        make_webhook_request('subscription_created.json')
      end
    end

    it 'returns a successful response' do
      expect(response).to have_http_status(200)
    end

    it 'returns a new event created' do
      expect(response.body).to eq(Message.event_processed_successfully)
    end

    it 'checks event has been added to database' do
      expect(ChargebeeWebhook.all.size).to eq(1)
    end

    it "checks event's name matches the one passed" do
      expect(ChargebeeWebhook.first.event_name).to eq(@body['event_type'])
    end

    it "checks event's id matches the one passed" do
      expect(ChargebeeWebhook.first.event_id).to eq(@body['id'])
    end

    it 'returns a event already processed when the same webhook is received' do
      make_webhook_request('subscription_created.json')
      expect(response).to have_http_status(200)
      expect(response.body).to eq(Message.event_already_processed)
    end

    it 'checks redundant event was not added to database' do
      expect(ChargebeeWebhook.all.size).to eq(1)
    end

    it 'returns event not supported when invalid webhook is received' do
      make_webhook_request('invalid_event_webhook.json')
      expect(response).to have_http_status(200)
      expect(response.body).to eq(Message.event_not_supported)
    end

    it 'returns 401 when credentials are not present' do
      @headers, @body = initialize_fake_chargebee_webhook('subscription_created.json')
      @headers.delete('Authorization')
      post(chargebee_api_endpoint, params: @body.to_json, headers: @headers)
      expect(response).to have_http_status(401)
      expect(response.body).to eq(Message.missing_token)
    end

    it 'returns 401 when credentials are invalid' do
      @headers, @body = initialize_fake_chargebee_webhook('subscription_created.json')
      @headers['Authorization'] = 'Basic invalid'
      post(chargebee_api_endpoint, params: @body.to_json, headers: @headers)
      expect(response).to have_http_status(401)
      expect(response.body).to eq(Message.invalid_token)
    end

    context 'handling a second webhook having new id and valid parameters' do
      before :all do
        VCR.use_cassette('second_subscription_created_request') do
          @headers, @body = initialize_fake_chargebee_webhook('subscription_created.json')
          @body['id'] = "#{@body['id']}_second_event_id"
          post(chargebee_api_endpoint, params: @body.to_json, headers: @headers)
        end
      end

      it 'returns a successful response - new ID' do
        expect(response).to have_http_status(200)
      end

      it 'returns a new event created - new ID' do
        expect(response.body).to eq(Message.event_processed_successfully)
      end

      it 'checks event has been added to database - new ID' do
        expect(ChargebeeWebhook.all.size).to eq(2)
      end

      it "checks event's name matches the one passed - new ID" do
        expect(ChargebeeWebhook.second.event_name).to eq(@body['event_type'])
      end

      it "checks event's id matches the one passed - new ID" do
        expect(ChargebeeWebhook.second.event_id).to eq(@body['id'])
      end

      it 'returns a event already processed when the same webhook is received - new ID' do
        post(chargebee_api_endpoint, params: @body.to_json, headers: @headers)
        expect(response).to have_http_status(200)
        expect(response.body).to eq(Message.event_already_processed)
      end
    end

    context 'handling a third webhook having new id and invalid parameters' do
      before :all do
        @headers, @body = initialize_fake_chargebee_webhook('subscription_created.json')
        @body['id'] = "#{@body['id']}_third_event_id"
        @body['content']['subscription'].delete('id')
        post(chargebee_api_endpoint, params: @body.to_json, headers: @headers)
      end

      it 'returns a unprocessible response - new ID' do
        expect(response).to have_http_status(422)
      end

      it 'returns invalid parameters provided - new ID' do
        expect(response.body).to eq(Message.unprocessable_parameters)
      end

      it 'checks new event is not added to database - new ID' do
        expect(ChargebeeWebhook.all.size).to eq(2)
      end
    end
  end
end
