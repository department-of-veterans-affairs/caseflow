# frozen_string_literal: true

require "rails_helper"
require "support/database_cleaner"

describe MissedJobSweeperJob, :postgres do
  let(:slack_service) { SlackService.new(url: "http://www.example.com") }

  before do
    allow(SlackService).to receive(:new).and_return(slack_service)
    allow(slack_service).to receive(:send_notification) { true }
  end

  context ".perform" do
    subject { described_class.perform_now }

    it "calls distribute!" do
      judge = create(:user, css_id: "MYNAMEISJUDGE")
      allow(judge).to receive(:judge_in_vacols?) { true }
      distribution = Distribution.create!(judge: judge)
      Timecop.travel(Time.zone.now + 1.hour + 1.minute) do
        subject

        # we'll get error status and that's ok. it's because we don't bother to set up appeals first.
        expect(distribution.reload).to be_error
        message = "Restarting jobs for Distributions: [#{distribution.id}]"
        expect(slack_service).to have_received(:send_notification).with(message).once
      end
    end
  end
end
