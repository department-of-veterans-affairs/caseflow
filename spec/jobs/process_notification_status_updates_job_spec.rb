# frozen_string_literal: true

describe ProcessNotificationStatusUpdatesJob, :postgres do
  include ActiveJob::TestHelper

  let(:redis) do
    Redis.new(url: Rails.application.secrets.redis_url_cache).tap(&:flushall)
  end

  context ".perform" do
    before do
      Seeds::NotificationEvents.new.seed!
    end

    let(:new_status) { "test_status" }
    let(:appeal) { create(:appeal, veteran_file_number: "500000102", receipt_date: 6.months.ago.to_date.mdY) }
    let(:email_notification) do
      create(:notification, appeals_id: appeal.uuid,
                            appeals_type: "Appeal",
                            event_date: 6.days.ago,
                            event_type: "Quarterly Notification",
                            email_notification_external_id: SecureRandom.uuid,
                            notification_type: "Email")
    end
    let(:sms_notification) do
      create(:notification, appeals_id: appeal.uuid,
                            appeals_type: "Appeal",
                            event_date: 6.days.ago,
                            event_type: "Hearing scheduled",
                            sms_notification_external_id: SecureRandom.uuid,
                            notification_type: "SMS")
    end

    it "processes email notifications from redis cache" do
      expect(email_notification.email_notification_status).to_not eq(new_status)

      redis.set("email_update:#{email_notification.email_notification_external_id}:#{new_status}", 0)

      expect(redis.keys.grep(/email_update:/).count).to eq(1)

      perform_enqueued_jobs { ProcessNotificationStatusUpdatesJob.perform_later }

      expect(redis.keys.grep(/email_update:/).count).to eq(0)
      expect(email_notification.reload.email_notification_status).to eq(new_status)
    end

    it "processes sms notifications from redis cache" do
      expect(sms_notification.sms_notification_status).to_not eq(new_status)

      redis.set("sms_update:#{sms_notification.sms_notification_external_id}:#{new_status}", 0)

      expect(redis.keys.grep(/sms_update:/).count).to eq(1)

      perform_enqueued_jobs { ProcessNotificationStatusUpdatesJob.perform_later }

      expect(redis.keys.grep(/sms_update:/).count).to eq(0)
      expect(sms_notification.reload.sms_notification_status).to eq(new_status)
    end

    it "processes a mix of email and sms notifications from redis cache" do
      redis.set("sms_update:#{sms_notification.sms_notification_external_id}:#{new_status}", 0)
      redis.set("email_update:#{email_notification.email_notification_external_id}:#{new_status}", 0)

      expect(redis.keys.grep(/(sms|email)_update:/).count).to eq(2)

      perform_enqueued_jobs { ProcessNotificationStatusUpdatesJob.perform_later }

      expect(redis.keys.grep(/(sms|email)_update:/).count).to eq(0)
      expect(email_notification.reload.email_notification_status).to eq(new_status)
      expect(sms_notification.reload.sms_notification_status).to eq(new_status)
    end

    it "an error is raised if a UUID doesn't match with a notification record, but the job isn't halted" do
      expect_any_instance_of(ProcessNotificationStatusUpdatesJob).to receive(:log_error) do |_job, error|
        expect(error.message).to eq("No notification matches UUID not-going-to-match")
      end.exactly(:once)

      # This notification update will cause an error
      redis.set("sms_update:not-going-to-match:#{new_status}", 0)

      # This notification update should be fine
      redis.set("email_update:#{email_notification.email_notification_external_id}:#{new_status}", 0)

      expect(redis.keys.grep(/(sms|email)_update:/).count).to eq(2)

      perform_enqueued_jobs { ProcessNotificationStatusUpdatesJob.perform_later }

      expect(sms_notification.reload.sms_notification_status).to be_nil
      expect(email_notification.reload.email_notification_status).to eq(new_status)

      expect(redis.keys.grep(/(sms|email)_update:/).count).to eq(0)
    end
  end
end
