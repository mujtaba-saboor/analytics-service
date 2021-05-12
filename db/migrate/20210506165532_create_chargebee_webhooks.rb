class CreateChargebeeWebhooks < ActiveRecord::Migration[6.0]
  def change
    create_table :chargebee_webhooks do |t|
      t.string :event_id
      t.string :event_name

      t.timestamps
    end
  end
end
