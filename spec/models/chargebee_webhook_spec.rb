require 'rails_helper'

RSpec.describe ChargebeeWebhook, type: :model do
  it { should validate_presence_of(:event_id) }
end
