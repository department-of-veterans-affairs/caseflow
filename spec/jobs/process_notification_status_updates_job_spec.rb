# frozen_string_literal: true

describe ProcessNotificationStatusUpdatesJob, :postgres do
  context ".perform" do
    subject { described_class.perform_now }

    it "processes notifications from redis cache" do
      # should we mock this?
      redis = Redis.new(url: Rails.application.secrets.redis_url_cache)

      # add notification statuses to redis
      5.times { |i| redis.set("email_update_test:1234#{i}:test_status", 0) }

      expect(redis.keys.grep(/email_update_test:/).count).to eq(5)

      # does this run?
      described_class.perform_now

      expect(redis.keys.grep(/email_update_test:/).count).to eq(0)
    end
  end
end
