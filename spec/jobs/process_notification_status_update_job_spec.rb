# frozen_string_literal: true

describe ProcessNotificationStatusUpdatesJob, :all_dbs do
  context ".perform" do
    subject { described_class.perform_now }

    it "processes notifications from redis cache" do
    end
  end
end
