# frozen_string_literal: true

require "helpers/retry_decision_review_processes"

describe RetryDecisionReviewProcesses do
  before do
    Timecop.freeze(Time.utc(2015, 1, 1, 12, 0, 0))
  end

  let(:subject) { RetryDecisionReviewProcesses.retry }
  let(:file_name) { "data-remediation-output-test/retry_decision_review_process_job-log-2015-01-01 07:00:00 -0500" }
  let(:supplemental_claim_1) do
    create :supplemental_claim, establishment_error: "
      Finds error that has a variable in it
      Transaction timed out after 10000 seconds
    "
  end
  let(:supplemental_claim_2) do
    create :supplemental_claim, establishment_error: "SomeUnknownError should get just the first word"
  end
  let(:higher_level_review) do
    create :higher_level_review, establishment_error: "DecisionDocument::NotYetSubmitted"
  end
  let(:request_issues_update) do
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

    let(:logs) do
      "RetryDecisionReviewProcesses Log\nRemediated SupplementalClaim: #{supplemental_claim_1.id} "\
        "Transaction timed out after seconds\nRemediated SupplementalClaim: #{supplemental_claim_2.id} "\
        "SomeUnknownError\nRemediated HigherLevelReview: #{higher_level_review.id} "\
        "DecisionDocument::NotYetSubmitted\nRemediated RequestIssuesUpdate: #{request_issues_update.id} "\
        "Can't create a SC DTA for appeal due to missing payee code"
    end

    it "#retry logs to S3" do
      expect(S3Service).to receive(:store_file).with(file_name, logs)
      subject
    end
  end

  describe "with unremediated errors" do
    let(:logs) { "RetryDecisionReviewProcesses Log\nNo successful remediations" }

    it "#retry logs to S3" do
      expect(S3Service).to receive(:store_file).with(file_name, logs)
      subject
    end
  end
end
