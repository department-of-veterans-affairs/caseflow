# frozen_string_literal: true

describe NotificationEvent do
  context "#create with nil values" do
    let(:event_type) { nil }
    let(:email_template_id) { nil }
    let(:sms_template_id) { nil }

    subject do
      NotificationEvent.create!(
        event_type: event_type,
        email_template_id: email_template_id,
        sms_template_id: sms_template_id
      )
    end
  end
end
