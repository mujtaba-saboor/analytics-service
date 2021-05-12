# frozen_string_literal: true

# ExceptionHandler contains error handling
module ExceptionHandler
  extend ActiveSupport::Concern

  class MissingToken < StandardError; end

  class InvalidToken < StandardError; end

  included do
    rescue_from Exception, with: :five_hundred
    rescue_from ExceptionHandler::MissingToken, with: :four_zero_one
    rescue_from ExceptionHandler::InvalidToken, with: :four_zero_one
  end

  private

  # Status code 422 - unprocessable entity
  def four_twenty_two(error)
    json_response(error.message, :unprocessable_entity)
  end

  # Status code 500 - internal server error
  def five_hundred(error)
    json_response(error.message, :internal_server_error)
  end

  # Status code 401 - unauthorized
  def four_zero_one(error)
    json_response(error.message, :unauthorized)
  end
end
