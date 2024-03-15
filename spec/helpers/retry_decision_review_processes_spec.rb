# frozen_string_literal: true

require "helpers/retry_decision_review_processes"

describe RetryDecisionReviewProcesses do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  shared_examples "#retry logs to S3" do
    it do
      expect(S3Service).to receive(:store_file).once.ordered.with(attempted_file_name, attempted_logs)
      expect(S3Service).to receive(:store_file).once.ordered.with(success_file_name, success_logs)
      expect(S3Service).to receive(:store_file).once.ordered.with(new_error_file_name, new_error_logs)
      subject
    end
  end

  let(:stuck_job_report_service) { StuckJobReportService.new }
  let(:subject) { RetryDecisionReviewProcesses.new(report_service: stuck_job_report_service).retry }
  let(:attempted_file_name) do
    "data-remediation-output-test/retry_decision_review_process_job-logs/"\
      "retry_decision_review_process_job_attempted-log-2015-01-01 07:00:00 -0500"
  end
  let(:success_file_name) do
    "data-remediation-output-test/retry_decision_review_process_job-logs/"\
      "retry_decision_review_process_job_success-log-2015-01-01 07:00:00 -0500"
  end
  let(:new_error_file_name) do
    "data-remediation-output-test/retry_decision_review_process_job-logs/"\
      "retry_decision_review_process_job_new_errors-log-2015-01-01 07:00:00 -0500"
  end
  let(:attempted_logs) { "RetryDecisionReviewProcesses Attempt Log" }
  let(:success_logs) { "RetryDecisionReviewProcesses Success Log\nNo successful remediations" }
  let(:new_error_logs) { "RetryDecisionReviewProcesses New Error Log\nNo new errors" }

  context "instances with errors" do
    let!(:supplemental_claim_1) do
      create :supplemental_claim, establishment_error: "
        Finds error that has a variable in it
        Transaction timed out after 10000 seconds
      "
    end
    let!(:supplemental_claim_2) do
      create :supplemental_claim, establishment_error: "SomeUnknownError should get just the first word"
    end
    let!(:higher_level_review) do
      create :higher_level_review, establishment_error: "DecisionDocument::NotYetSubmitted"
    end
    let!(:request_issues_update) do
      create :request_issues_update, error: "
        Finds error that has a variable in it
        Can't create a SC DTA for appeal 030310 due to missing payee code
      "
    end

    describe "with remediated errors" do
      before do
        allow(DecisionReviewProcessJob).to receive(:perform_now) do |instance|
          if instance.is_a?(RequestIssuesUpdate)
            instance.update(error: nil)
          else
            instance.update(establishment_error: nil)
          end
        end
      end

      let(:success_logs) do
        "RetryDecisionReviewProcesses Success Log\nSupplementalClaim: #{supplemental_claim_1.id} "\
          "Transaction timed out after seconds\nSupplementalClaim: #{supplemental_claim_2.id} "\
          "SomeUnknownError\nHigherLevelReview: #{higher_level_review.id} "\
          "DecisionDocument::NotYetSubmitted\nRequestIssuesUpdate: #{request_issues_update.id} "\
          "Can't create a SC DTA for appeal due to missing payee code"
      end
      let(:attempted_logs) do
        "RetryDecisionReviewProcesses Attempt Log\nSupplementalClaim: #{supplemental_claim_1.id} "\
          "Transaction timed out after seconds\nSupplementalClaim: #{supplemental_claim_2.id} "\
          "SomeUnknownError\nHigherLevelReview: #{higher_level_review.id} "\
          "DecisionDocument::NotYetSubmitted\nRequestIssuesUpdate: #{request_issues_update.id} "\
          "Can't create a SC DTA for appeal due to missing payee code"
      end

      it_behaves_like "#retry logs to S3"
    end

    describe "new error introduced" do
      before do
        allow(DecisionReviewProcessJob).to receive(:perform_now) do |instance|
          if instance.is_a?(RequestIssuesUpdate)
            instance.update(error: "BrandNewError")
          else
            instance.update(establishment_error: "BrandNewError")
          end
        end
      end

      let(:new_error_logs) do
        "RetryDecisionReviewProcesses New Error Log\nSupplementalClaim: #{supplemental_claim_1.id} BrandNewError\n"\
          "SupplementalClaim: #{supplemental_claim_2.id} BrandNewError\nHigherLevelReview: #{higher_level_review.id} "\
          "BrandNewError\nRequestIssuesUpdate: #{request_issues_update.id} BrandNewError"
      end
      let(:attempted_logs) do
        "RetryDecisionReviewProcesses Attempt Log\nSupplementalClaim: #{supplemental_claim_1.id} "\
          "Transaction timed out after seconds\nSupplementalClaim: #{supplemental_claim_2.id} "\
          "SomeUnknownError\nHigherLevelReview: #{higher_level_review.id} "\
          "DecisionDocument::NotYetSubmitted\nRequestIssuesUpdate: #{request_issues_update.id} "\
          "Can't create a SC DTA for appeal due to missing payee code"
      end

      it_behaves_like "#retry logs to S3"
    end
  end

  context "instances with exceptions" do
    before do
      allow(DecisionReviewProcessJob).to receive(:perform_now).and_raise(ActiveRecord::RecordNotUnique)
    end

    let!(:supplemental_claim_1) do
      create :supplemental_claim, establishment_error: "
        Finds error that has a variable in it
        Transaction timed out after 10000 seconds
      "
    end
    let(:attempted_logs) do
      "RetryDecisionReviewProcesses Attempt Log\nSupplementalClaim: #{supplemental_claim_1.id} "\
        "Transaction timed out after seconds"
    end

    it do
      subject
      expect(stuck_job_report_service.logs.last).to include("ActiveRecord::RecordNotUnique")
    end

    it_behaves_like "#retry logs to S3"
  end

  describe "with nothing to log" do
    it_behaves_like "#retry logs to S3"
  end
end
