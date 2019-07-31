# frozen_string_literal: true

require "rails_helper"

describe DataIntegrityChecksJob do
  let(:expired_async_jobs_checker) { ExpiredAsyncJobsChecker.new }
  let(:open_hearing_tasks_without_active_descendants_checker) { OpenHearingTasksWithoutActiveDescendantsChecker.new }
  let(:untracked_legacy_appeals_checker) { UntrackedLegacyAppealsChecker.new }
  let(:slack_service) { SlackService.new(url: "http://www.example.com") }

  before do
    allow(ExpiredAsyncJobsChecker).to receive(:new).and_return(expired_async_jobs_checker)
    allow(OpenHearingTasksWithoutActiveDescendantsChecker).to receive(:new).and_return(
      open_hearing_tasks_without_active_descendants_checker
    )
    allow(UntrackedLegacyAppealsChecker).to receive(:new).and_return(untracked_legacy_appeals_checker)
    allow(SlackService).to receive(:new).and_return(slack_service)
    [
      expired_async_jobs_checker,
      open_hearing_tasks_without_active_descendants_checker,
      untracked_legacy_appeals_checker
    ].each do |checker|
      allow(checker).to receive(:call).and_call_original
      allow(checker).to receive(:report?).and_call_original
      allow(checker).to receive(:report).and_call_original
    end
    allow(slack_service).to receive(:send_notification).and_return(true)
  end

  describe "#perform" do
    it "does not send slack notifications unless there is a report" do
      described_class.perform_now

      expect(expired_async_jobs_checker).to have_received(:call).once
      expect(expired_async_jobs_checker).to have_received(:report?).once
      expect(expired_async_jobs_checker).to_not have_received(:report)

      expect(open_hearing_tasks_without_active_descendants_checker).to have_received(:call).once
      expect(open_hearing_tasks_without_active_descendants_checker).to have_received(:report?).once
      expect(open_hearing_tasks_without_active_descendants_checker).to_not have_received(:report)

      expect(untracked_legacy_appeals_checker).to have_received(:call).once
      expect(untracked_legacy_appeals_checker).to have_received(:report?).once
      expect(untracked_legacy_appeals_checker).to_not have_received(:report)

      expect(slack_service).to_not have_received(:send_notification)
    end

    context "expired async jobs exist" do
      before do
        expired_async_jobs_checker.add_to_report "1 expired async job"
      end

      it "sends slack notification if there is a report" do
        described_class.perform_now

        expect(expired_async_jobs_checker).to have_received(:call).once
        expect(expired_async_jobs_checker).to have_received(:report?).once
        expect(expired_async_jobs_checker).to have_received(:report).once
        expect(slack_service).to have_received(:send_notification)
      end
    end
  end
end
