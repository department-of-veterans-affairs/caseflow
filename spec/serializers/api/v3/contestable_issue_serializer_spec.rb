# frozen_string_literal: true

describe Api::V3::ContestableIssueSerializer, :postgres do
  include IntakeHelpers

  before do
    Time.zone = "UTC"
    Timecop.freeze(Time.utc(2018, 1, 1, 12, 0, 0))
  end

  let(:benefit_type) { "compensation" }
  let(:decision_text) { "This broadcast may not be reproduced" }
  let(:diagnostic_code) { "1234" }
  let(:profile_date) { Time.zone.now - 30.days }
  let(:promulgation_date) { Time.zone.now - 29.days }
  let(:decision_review) { create :higher_level_review }

  context "rating issue" do
    let(:rating_issue) do
      RatingIssue.new(
        associated_end_products: associated_end_products,
        benefit_type: benefit_type,
        decision_text: decision_text,
        diagnostic_code: diagnostic_code,
        participant_id: participant_id,
        percent_number: percent_number,
        profile_date: profile_date,
        promulgation_date: promulgation_date,
        rba_contentions_data: rba_contentions_data,
        reference_id: reference_id,
        subject_text: subject_text
      )
    end

    let(:associated_end_products) { [] }
    let(:participant_id) { "123" }
    let(:percent_number) { 50 }
    let(:rba_contentions_data) { [{}] }
    let(:reference_id) { "NBA" }
    let(:subject_text) { "unreproducible broadcast - 50% rating" }

    subject do
      described_class.new(
        ContestableIssue.from_rating_issue(rating_issue, decision_review)
      ).serializable_hash.as_json
    end

    it "serializes the rating issue" do
      is_expected.to eq(
        {
          data: {
            id: nil,
            type: :contestableIssue,
            attributes: {
              ratingIssueProfileDate: profile_date.strftime("%F"),
              ratingIssueReferenceId: reference_id,
              ratingIssueDiagnosticCode: diagnostic_code,
              ratingIssueSubjectText: subject_text,
              ratingIssuePercentNumber: percent_number,
              description: decision_text,
              isRating: true,
              latestIssuesInChain: [{ id: nil, approxDecisionDate: promulgation_date.strftime("%F") }],
              decisionIssueId: nil,
              ratingDecisionReferenceId: nil,
              approxDecisionDate: promulgation_date.strftime("%F"),
              rampClaimId: nil,
              titleOfActiveReview: nil,
              sourceReviewType: nil,
              timely: true
            }
          }
        }.as_json
      )
    end
  end

  context "decision issue" do
    let(:decision_issue) do
      create(
        :decision_issue,
        benefit_type: benefit_type,
        caseflow_decision_date: caseflow_decision_date,
        decision_review: decision_review,
        decision_text: decision_text,
        description: description,
        diagnostic_code: diagnostic_code,
        disposition: disposition,
        end_product_last_action_date: end_product_last_action_date,
        rating_profile_date: profile_date,
        rating_promulgation_date: promulgation_date,
        request_issues: request_issues
      )
    end

    let(:caseflow_decision_date) { 20.days.ago }
    let(:decision_date) { 9.days.ago }
    let(:description) { "description" }
    let(:disposition) { "allowed" }
    let(:end_product_last_action_date) { 10.days.ago }
    let(:request_issues) { [] }

    subject do
      described_class.new(
        ContestableIssue.from_decision_issue(decision_issue, decision_review)
      ).serializable_hash
    end

    it "serializes the decision issue" do
      is_expected.to eq(
        data: {
          id: nil,
          type: :contestableIssue,
          attributes: {
            ratingIssueProfileDate: profile_date.strftime("%F"),
            ratingIssueReferenceId: nil,
            ratingIssueDiagnosticCode: nil,
            ratingIssueSubjectText: nil,
            ratingIssuePercentNumber: nil,
            description: description,
            isRating: true,
            latestIssuesInChain: [{ id: decision_issue.id, approxDecisionDate: promulgation_date.strftime("%F") }],
            decisionIssueId: decision_issue.id,
            ratingDecisionReferenceId: nil,
            approxDecisionDate: promulgation_date.strftime("%F"),
            rampClaimId: nil,
            titleOfActiveReview: nil,
            sourceReviewType: nil,
            timely: true
          }
        }
      )
    end
  end
end
