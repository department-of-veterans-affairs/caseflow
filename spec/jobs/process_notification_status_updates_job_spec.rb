# frozen_string_literal: true

describe ProcessNotificationStatusUpdatesJob, :postgres do
  context ".perform" do
    before do
      Seeds::NotificationEvents.new.seed!
    end

    let(:appeal) { create(:appeal, veteran_file_number: "500000102", receipt_date: 6.months.ago.to_date.mdY) }
    let!(:notification) do
      create(:notification, appeals_id: appeal.uuid,
                            appeals_type: "Appeal",
                            event_date: 6.days.ago,
                            event_type: "Quarterly Notification",
                            notification_type: "Email")
    end

    it "processes notifications from redis cache" do
      redis = Redis.new(url: Rails.application.secrets.redis_url_cache)

      # clean-up any keys left behind
      redis.scan_each(match: "*_update:*") { |key| redis.del(key) }

      redis.set("email_update:#{notification.id}:test_status", 0)

      expect(redis.keys.grep(/email_update:/).count).to eq(1)

      # does this run?
      described_class.perform_now

      expect(redis.keys.grep(/email_update:/).count).to eq(0)
    end
  end
end
