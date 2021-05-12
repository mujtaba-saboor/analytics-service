# frozen_string_literal: true

# Message.rb contains all the relevant messages
class Message
  def self.something_went_wrong
    'Something went wrong'
  end

  def self.invalid_token
    'Invalid Basic Authorization token'
  end

  def self.missing_token
    'Missing Basic Authorization token'
  end

  def self.unauthorized
    'Unauthorized request'
  end

  def self.unprocessable_parameters
    'Invalid parameters provided'
  end

  def self.event_processed_successfully
    'Event Processed Successfully'
  end

  def self.event_not_supported
    'Event Not Supported'
  end

  def self.event_already_processed
    'Event Already Processed'
  end
end
