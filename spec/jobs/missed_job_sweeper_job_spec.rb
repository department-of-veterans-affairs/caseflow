# frozen_string_literal: true

require "rails_helper"

describe MissedJobSweeperJob do
  context ".perform" do
    it "calls distribute! and sends a slack notification" do
      slack_service = double("SlackService")
      allow(slack_service).to receive(:send_notification) { true }
      allow_any_instance_of(described_class).to receive(:slack_service).and_return(slack_service)

      distribution_id = 111
      distribution = double("Distribution", id: distribution_id, judge: double("User"))
      allow(distribution).to receive(:distribute!)
      allow(Distribution).to receive(:pending).and_return(Distribution)
      allow(Distribution).to receive(:where).with("created_at < ?", kind_of(ActiveSupport::TimeWithZone)) do |*args|
        expect(args[1]).to be >= 1.hour.ago
      end.and_return([distribution])

      described_class.perform_now

      expect(distribution).to have_received(:distribute!).once
      message = "Restarting jobs for Distributions: [#{distribution_id}]"
      expect(slack_service).to have_received(:send_notification).with(message).once
    end
  end
end
