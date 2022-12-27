# frozen_string_literal: true

describe Notification do
  context "#create with nil values" do
    let(:appeals_type) { nil }
    let(:created_at) { DateTime.now }
    let(:email_notification_status) { nil }
    let(:event_date) { DateTime.now }
    let(:event_type) { nil }
    let(:notification_content) { nil }
    let(:notification_events_id) { nil }
    let(:notification_type) { nil }
    let(:notified_at) { DateTime.now }
    let(:participant_id) { nil }
    let(:recipient_email) { nil }
    let(:recipient_phone_number) { nil }
    let(:sms_notification_status) { nil }
    let(:updated_at) { DateTime.now }

    subject do
      Notification.create!(
        appeals_type: appeals_type,
        created_at: created_at,
        email_notification_status: email_notification_status,
        event_date: event_date,
        event_type: event_type,
        notfication_content: notification_content,
        notification_events_id: notification_events_id,
        notification_type: notification_type,
        notified_at: notified_at,
        participant_id: participant_id,
        recipient_email: recipient_email,
        recipient_phone_number: recipient_phone_number,
        sms_notification_status: sms_notification_status,
        updated_at: updated_at
      )
    end
  end
end
