# frozen_string_literal: true

describe IneligibleJudgesJob, :all_dbs do
  context "when successful job occurs" do
    # {Test successful slack message}
  end

  context "when error occurs" do
    # {Not complete just a basic example from other job specs. Need to test for slack and sentry error messages}
    subject { job.perform_now }
    let(:job) { described_class.new }
    let(:slack_service) { SlackService.new(url: "http://www.example.com") }

    it "sends alert to Sentry and Slack" do
      subject

      expect(slack_service).to have_received(:send_notification).with(
        "Error running ETLBuilderJob. See Sentry event sentry_12345",
        "ETLBuilderJob"
      )
      expect(@raven_called).to eq(true)
    end

    it "saves Exception messages and logs error" do
      allow(Raven).to receive(:capture_exception) { @raven_called = true }
      allow_any_instance_of(IneligibleJudgesJob).to receive(:sync!).and_raise(bgs_error)

      IneligibleJudgesJob.perform_now

      expect(@raven_called).to eq(true)
    end
  end
end
