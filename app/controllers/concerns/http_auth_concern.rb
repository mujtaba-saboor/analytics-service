# frozen_string_literal: true

# http_auth_concern contains authentication of Basic Authorization token
module HttpAuthConcern
  extend ActiveSupport::Concern
  include ActionController::HttpAuthentication::Basic::ControllerMethods

  ALLOWED_BASIC_AUTHORIZATION = { 'chargebee_webhooks' => { username: Rails.configuration.chargebee_webhook_username, password: Rails.configuration.chargebee_webhook_password } }.freeze

  included do
    before_action :http_authenticate
  end

  def http_authenticate
    raise ExceptionHandler::MissingToken, Message.missing_token unless ActionController::HttpAuthentication::Basic.has_basic_credentials?(request)

    valid_request = authenticate_with_http_basic do |username, password|
      ALLOWED_BASIC_AUTHORIZATION.dig(controller_name, :username) == username && ALLOWED_BASIC_AUTHORIZATION.dig(controller_name, :password) == password
    end

    return if valid_request

    raise ExceptionHandler::InvalidToken, Message.invalid_token
  end
end
