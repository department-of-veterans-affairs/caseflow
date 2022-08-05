# frozen_string_literal: true

describe NotificationEvent do
  context "#create with nil values" do
    let(:event_type) { nil }
    let(:template_id) { nil }
    subject do
      NotificationEvent.create!(
        event_type: event_type,
        template_id: template_id
      )
    end
  end
end
