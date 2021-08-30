# frozen_string_literal: true

describe DataIntegrityChecksJob do
  let(:expired_async_jobs_checker) { ExpiredAsyncJobsChecker.new }
  let(:open_hearing_tasks_without_active_descendants_checker) { OpenHearingTasksWithoutActiveDescendantsChecker.new }
  let(:untracked_legacy_appeals_checker) { UntrackedLegacyAppealsChecker.new }
  let(:reviews_with_duplicate_ep_error_checker) { ReviewsWithDuplicateEpErrorChecker.new }
  let(:stuck_virtual_hearings_checker) { StuckVirtualHearingsChecker.new }
  let(:appeals_with_more_than_one_open_hearing_task_checker) { AppealsWithMoreThanOneOpenHearingTaskChecker.new }
  let(:decision_date_checker) { DecisionDateChecker.new }
  let(:slack_service) { SlackService.new(url: "http://www.example.com") }
  let(:slack_messages) { [] }

  before do
    allow(ExpiredAsyncJobsChecker).to receive(:new).and_return(expired_async_jobs_checker)
    allow(OpenHearingTasksWithoutActiveDescendantsChecker).to receive(:new).and_return(
      open_hearing_tasks_without_active_descendants_checker
    )
    allow(UntrackedLegacyAppealsChecker).to receive(:new).and_return(untracked_legacy_appeals_checker)
    allow(ReviewsWithDuplicateEpErrorChecker).to receive(:new).and_return(reviews_with_duplicate_ep_error_checker)
    allow(StuckVirtualHearingsChecker).to receive(:new).and_return(stuck_virtual_hearings_checker)
    allow(AppealsWithMoreThanOneOpenHearingTaskChecker).to receive(:new).and_return(
      appeals_with_more_than_one_open_hearing_task_checker
    )
    allow(DecisionDateChecker).to receive(:new).and_return(decision_date_checker)
    allow(SlackService).to receive(:new).and_return(slack_service)
    [
      expired_async_jobs_checker,
      open_hearing_tasks_without_active_descendants_checker,
      untracked_legacy_appeals_checker,
      reviews_with_duplicate_ep_error_checker,
      stuck_virtual_hearings_checker,
      appeals_with_more_than_one_open_hearing_task_checker,
      decision_date_checker
    ].each do |checker|
      allow(checker).to receive(:call).and_call_original
      allow(checker).to receive(:report?).and_call_original
      allow(checker).to receive(:report).and_call_original
    end
    allow(slack_service).to receive(:send_notification) { |msg| slack_messages << msg }

    @emitted_gauges = []
    allow(DataDogService).to receive(:emit_gauge) do |args|
      @emitted_gauges.push(args)
    end

    allow(Raven).to receive(:capture_exception) { @raven_called = true }
    allow(Raven).to receive(:last_event_id) { @raven_called && "sentry_12345" }
  end

  describe "#perform" do
    subject { described_class.perform_now }

    it "updates DataDog" do
      subject

      expect(@emitted_gauges).to include(
        app_name: "caseflow_job",
        metric_group: "data_integrity_checks_job",
        metric_name: "runtime",
        metric_value: anything
      )
      expect(@emitted_gauges).to include(
        app_name: "caseflow_job_segment",
        metric_group: "expired_async_jobs_checker",
        metric_name: "runtime",
        metric_value: anything
      )
    end

    it "does not send slack notifications unless there is a report" do
      subject

      expect(expired_async_jobs_checker).to have_received(:call).once
      expect(expired_async_jobs_checker).to have_received(:report?).once
      expect(expired_async_jobs_checker).to_not have_received(:report)

      expect(open_hearing_tasks_without_active_descendants_checker).to have_received(:call).once
      expect(open_hearing_tasks_without_active_descendants_checker).to have_received(:report?).once
      expect(open_hearing_tasks_without_active_descendants_checker).to_not have_received(:report)

      expect(untracked_legacy_appeals_checker).to have_received(:call).once
      expect(untracked_legacy_appeals_checker).to have_received(:report?).once
      expect(untracked_legacy_appeals_checker).to_not have_received(:report)

      expect(reviews_with_duplicate_ep_error_checker).to have_received(:call).once
      expect(reviews_with_duplicate_ep_error_checker).to have_received(:report?).once
      expect(reviews_with_duplicate_ep_error_checker).to_not have_received(:report)

      expect(stuck_virtual_hearings_checker).to have_received(:call).once
      expect(stuck_virtual_hearings_checker).to have_received(:report?).once
      expect(stuck_virtual_hearings_checker).to_not have_received(:report)

      expect(appeals_with_more_than_one_open_hearing_task_checker).to have_received(:call).once
      expect(appeals_with_more_than_one_open_hearing_task_checker).to have_received(:report?).once
      expect(appeals_with_more_than_one_open_hearing_task_checker).to_not have_received(:report)

      expect(decision_date_checker).to have_received(:call).once
      expect(decision_date_checker).to have_received(:report?).once
      expect(decision_date_checker).to_not have_received(:report)

      expect(slack_service).to_not have_received(:send_notification)
    end

    context "expired async jobs exist" do
      before do
        expired_async_jobs_checker.add_to_report "[INFO] 1 expired async job"
        untracked_legacy_appeals_checker.add_to_report "legacy appeals are untracked"
      end

      it "sends slack notification if there is a report" do
        subject

        expect(expired_async_jobs_checker).to have_received(:call).once
        expect(expired_async_jobs_checker).to have_received(:report?).once
        expect(expired_async_jobs_checker).to have_received(:report).once
        expect(slack_service).to have_received(:send_notification).twice
        expect(slack_messages.any? { |msg| msg =~ /^\[INFO\] 1 expired async job/ }).to eq(true)
        expect(slack_messages.any? { |msg| msg =~ /^\[WARN\] legacy appeals are untracked/ }).to eq(true)
      end
    end

    context "one report throws an error" do
      before do
        allow(expired_async_jobs_checker).to receive(:call) { fail StandardError, "oops!" }
      end

      it "rescues error and logs to sentry and slack" do
        subject

        expect(slack_service).to have_received(:send_notification).with(
          "Error running ExpiredAsyncJobsChecker. See Sentry event sentry_12345",
          "ExpiredAsyncJobsChecker",
          "#appeals-foxtrot"
        )
        expect(@raven_called).to eq(true)
      end
    end
  end
end
