# frozen_string_literal: true

# service responsible to ping webhooks to iterative.ly
class ChargebeeWebhooksService
  WEBHOOKS_SUPPORTED = %w[subscription_created subscription_changed subscription_paused subscription_cancelled payment_failed order_created].freeze
  USER_ID = 'kabo-analytics'

  def initialize(event_type)
    @event_type = event_type
  end

  def push_to_iteratively(parameters)
    service_result = {}

    return service_result unless new_event_and_supported?(parameters, service_result)

    begin
      case @event_type
      when 'subscription_created'
        Itly.subscription_created(USER_ID, **subscription_created_data_values(parameters))
      when 'subscription_paused'
        Itly.subscription_paused(USER_ID, **subscription_paused_data_values(parameters))
      when 'subscription_changed'
        # Itly.subscription_changed(USER_ID, **subscription_changed_data_values(parameters))
      when 'subscription_cancelled'
        Itly.subscription_cancelled(USER_ID, **subscription_cancelled_data_values(parameters))
      when 'payment_failed'
        Itly.payment_failed(USER_ID, **payment_failed_data_values(parameters))
      when 'order_created'
        # Itly.order_completed(USER_ID, **order_created_data_values(parameters))
      end

      create_webhook_entry(parameters[:id])

      { api_response: Message.event_processed_successfully, status_code: :ok }
    rescue Itly::ValidationError
      { api_response: Message.unprocessable_parameters, status_code: :unprocessable_entity }
    end
  end

  def subscription_created_data_values(parameters)
    billing_period_unit = parameters.dig(:content, :subscription, :billing_period_unit)
    subscription_value = parameters.dig(:content, :invoice, :total) || 0

    if billing_period_unit == 'week'
      subscription_time_interval = 14
      mrr_factor = 24
    else
      subscription_time_interval = 28
      mrr_factor = 12
    end

    discount_codes = []
    parameters.dig(:content, :invoice, :discounts)&.each { |discount| discount_codes << discount[:entity_id] }

    products = []
    parameters.dig(:content, :invoice, :line_items)&.each { |line_item| products << line_item[:entity_id] }

    { subscription_time_interval: subscription_time_interval,
      subscription_value: subscription_value.to_s,
      subscription_mrr: (subscription_value * (52 / mrr_factor)).to_s,
      subscription_id: parameters.dig(:content, :subscription, :id),
      discount_code: discount_codes.join(', '),
      products: products.join(', ') }
  end

  # TO-DO properties: subscription_value, paused_reason, pause_type, and products should be added later.
  def subscription_paused_data_values(parameters)
    billing_period_unit = parameters.dig(:content, :subscription, :billing_period_unit)
    subscription_time_interval = billing_period_unit == 'week' ? 14 : 28

    resume_date = parameters.dig(:content, :subscription, :resume_date)
    pause_date = parameters.dig(:content, :subscription, :pause_date)
    pause_length = (Time.at(resume_date).to_date - Time.at(pause_date).to_date).to_i rescue 0

    { subscription_time_interval: subscription_time_interval,
      subscription_value: '',
      subscription_mrr: parameters.dig(:content, :subscription, :mrr).to_s,
      subscription_id: parameters.dig(:content, :subscription, :id),
      paused_reason: '',
      pause_length: pause_length,
      pause_type: '',
      products: '' }
  end

  def subscription_changed_data_values(parameters)
    # to do later
  end

  # TO-DO properties: subscription_value, cancel_reason, and products should be added later.
  def subscription_cancelled_data_values(parameters)
    cancelled_at = Time.at(parameters.dig(:content, :subscription, :cancelled_at)).to_s rescue ''

    { subscription_cancel_request_date: cancelled_at,
      subscription_value: '',
      subscription_mrr: parameters.dig(:content, :subscription, :mrr).to_s,
      subscription_id: parameters.dig(:content, :subscription, :id),
      cancel_reason: '',
      products: '' }
  end

  def payment_failed_data_values(parameters)
    billing_period_unit = parameters.dig(:content, :subscription, :billing_period_unit)
    subscription_value = parameters.dig(:content, :invoice, :total)
    time_interval = billing_period_unit == 'week' ? 14 : 28

    { subscription_value: subscription_value.to_s,
      subscription_mrr: parameters.dig(:content, :subscription, :mrr).to_s,
      subscription_id: parameters.dig(:content, :subscription, :id),
      time_interval: time_interval }
  end

  def order_created_data_values(parameters)
    products = []
    parameters.dig(:content, :order, :order_line_items)&.each { |line_item| products << line_item[:entity_id] }

    { total_shipping: ''.to_f,
      subtotal_price: parameters.dig(:content, :order, :sub_total).to_f,
      discount_code: '',
      total_price: parameters.dig(:content, :order, :total).to_f,
      total_tax: parameters.dig(:content, :order, :tax).to_f,
      first_name: '',
      last_name: '',
      order_id: parameters.dig(:content, :order, :id),
      products: products.join(', '),
      revenue: ''.to_f }
  end

  def create_webhook_entry(event_id)
    ChargebeeWebhook.create(event_id: event_id, event_name: @event_type)
  end

  def new_event_and_supported?(parameters, service_result)
    if WEBHOOKS_SUPPORTED.exclude?(@event_type)
      service_result.merge!(api_response: Message.event_not_supported, status_code: :ok)
      return false

    end

    if existing_event?(parameters[:id])
      service_result.merge!(api_response: Message.event_already_processed, status_code: :ok)
      return false

    end
    true
  end

  def existing_event?(event_id)
    ChargebeeWebhook.where(event_id: event_id).any?
  end
end
