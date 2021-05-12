class Api::V1::ChargebeeWebhooksController < ApplicationController
  def create
    service_response = ChargebeeWebhooksService.new(params[:event_type]).push_to_iteratively(params.to_unsafe_h)
    json_response(service_response[:api_response], service_response[:status_code])
  end
end
