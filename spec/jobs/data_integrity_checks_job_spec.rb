# frozen_string_literal: true

describe DataIntegrityChecksJob do
  let(:expired_async_jobs_checker) { ExpiredAsyncJobsChecker.new }
  let(:untracked_legacy_appeals_checker) { UntrackedLegacyAppealsChecker.new }
  let(:slack_service) { SlackService.new(url: "http://www.example.com") }

  before do
    allow(ExpiredAsyncJobsChecker).to receive(:new).and_return(expired_async_jobs_checker)
    allow(UntrackedLegacyAppealsChecker).to receive(:new).and_return(untracked_legacy_appeals_checker)
    allow(SlackService).to receive(:new).and_return(slack_service)
    [expired_async_jobs_checker, untracked_legacy_appeals_checker].each do |checker|
      allow(checker).to receive(:call).and_call_original
      allow(checker).to receive(:report?).and_call_original
      allow(checker).to receive(:report).and_call_original
    end
    allow(slack_service).to receive(:send_notification).and_call_original
  end

  describe "#perform" do
    it "does not send slack notifications unless there is a report" do
      described_class.perform_now

      expect(expired_async_jobs_checker).to have_received(:call).once
      expect(expired_async_jobs_checker).to have_received(:report?).once
      expect(expired_async_jobs_checker).to_not have_received(:report)

      expect(untracked_legacy_appeals_checker).to have_received(:call).once
      expect(untracked_legacy_appeals_checker).to have_received(:report?).once
      expect(untracked_legacy_appeals_checker).to_not have_received(:report)

      expect(slack_service).to_not have_received(:send_notification)
    end
  end
end
