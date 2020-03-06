# frozen_string_literal: true

describe OutOfServiceReminderJob do
  context "when single apps are disabled" do
    before do
      allow_any_instance_of(SlackService).to receive(:send_notification)
        .with("Reminder: Dispatch and Reader are out of service.")
        .and_return("Reminder: Dispatch and Reader are out of service.")
    end

    it "reports that apps are out of service" do
      Rails.cache.write("reader_out_of_service", true)
      Rails.cache.write("dispatch_out_of_service", true)
      expect(OutOfServiceReminderJob.perform_now).to eq("Reminder: Dispatch and Reader are out of service.")
    end

    it "does not report otherwise" do
      expect(OutOfServiceReminderJob.perform_now).to eq(nil)
    end
  end

  context "when both single apps and global are disabled" do
    before do
      allow_any_instance_of(SlackService).to receive(:send_notification)
        .with("Reminder: Caseflow has been taken out of service.")
        .and_return("Reminder: Caseflow has been taken out of service.")
    end

    it "reports only that Caseflow is out of service" do
      Rails.cache.write("reader_out_of_service", true)
      Rails.cache.write("dispatch_out_of_service", true)
      Rails.cache.write("out_of_service", true)
      expect(OutOfServiceReminderJob.perform_now).to eq("Reminder: Caseflow has been taken out of service.")
    end
  end
end
