# frozen_string_literal: true

describe IncompleteDistributionsJob, :postgres do
  let(:slack_service) { SlackService.new(url: "http://www.example.com") }

  before do
    allow(SlackService).to receive(:new).and_return(slack_service)
    allow(slack_service).to receive(:send_notification) { true }
  end

  context ".perform" do
    subject { described_class.perform_now }

    let(:judge) do
      create(:user, :judge, :with_vacols_judge_record, css_id: "MYNAMEISJUDGE")
    end
    let!(:distribution) { Distribution.create!(judge: judge) }

    it "detects pending Distribution" do
      Timecop.travel(Time.zone.now + 1.hour + 1.minute) do
        subject

        message = "Restarting jobs for pending Distributions: [#{distribution.id}]"
        expect(slack_service).to have_received(:send_notification).with(message).once
      end
    end

    it "detects stalled Distribution" do
      distribution.started_at = Time.zone.now
      distribution.started!
      Timecop.travel(Time.zone.now + 1.hour + 1.minute) do
        subject

        message = "Restarting jobs for stalled Distributions: [#{distribution.id}]"
        expect(slack_service).to have_received(:send_notification).with(message).once
      end
    end

    it "detects stalled Distribution without started_at" do
      distribution.started!
      Timecop.travel(Time.zone.now + 1.hour + 1.minute) do
        subject

        message = "Restarting jobs for stalled Distributions: [#{distribution.id}]"
        expect(slack_service).to have_received(:send_notification).with(message).once
      end
    end

    context "there are no incomplete Distributions" do
      it "doesn't send a slack message" do
        Timecop.travel(Time.zone.now + 30.minutes) do
          subject

          expect(slack_service).to_not have_received(:send_notification)
        end
      end
    end
  end
end
