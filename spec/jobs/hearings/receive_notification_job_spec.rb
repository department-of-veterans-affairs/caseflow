# frozen_string_literal: true

describe ReceiveNotificationJob, type: :job do
  include ActiveJob::TestHelper
  let(:current_user) { create(:user, roles: ["System Admin"]) }
  # rubocop:disable Style/BlockDelimiters
  let(:message) {
    {
      queue_url: "http://example_queue",
      message_body: "Notification",
      message_attributes: {

      }
    }
  }
end