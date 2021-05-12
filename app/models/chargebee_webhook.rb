# frozen_string_literal: true

class ChargebeeWebhook < ApplicationRecord
  validates :event_id, presence: true, uniqueness: { message: 'event already processed' }

end
