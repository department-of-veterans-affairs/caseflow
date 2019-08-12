# frozen_string_literal: true

require "rails_helper"

describe OutOfServiceReminderJob do
  context "when single apps are disabled" do
    it "reports that apps are out of service" do
      Rails.cache.write("reader_out_of_service", true)
      Rails.cache.write("dispatch_out_of_service", true)
      slack_service = instance_double(SlackService)
      expected_msg = "Reminder: Dispatch and Reader are out of service."

      expect(SlackService).to receive(:new).with(msg: expected_msg).and_return(slack_service)
      expect(slack_service).to receive(:send_notification)

      OutOfServiceReminderJob.perform_now
    end

    it "does not report otherwise" do
      expect(SlackService).to_not receive(:new)

      OutOfServiceReminderJob.perform_now
    end
  end

  context "when both single apps and global are disabled" do
    it "reports only that Caseflow is out of service" do
      Rails.cache.write("reader_out_of_service", true)
      Rails.cache.write("dispatch_out_of_service", true)
      Rails.cache.write("out_of_service", true)

      slack_service = instance_double(SlackService)
      expected_msg = "Reminder: Caseflow has been taken out of service."

      expect(SlackService).to receive(:new).with(msg: expected_msg).and_return(slack_service)
      expect(slack_service).to receive(:send_notification)

      OutOfServiceReminderJob.perform_now
    end
  end
end
