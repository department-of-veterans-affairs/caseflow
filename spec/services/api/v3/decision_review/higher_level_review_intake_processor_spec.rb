# frozen_string_literal: true

require "support/intake_helpers"
require "pp"

describe Api::V3::DecisionReview::IntakeProcessor, :all_dbs do
  include IntakeHelpers

  subject { Api::V3::DecisionReview::HigherLevelReviewIntakeProcessor.new(params, user) }

  let(:user) { current_user }
  let(:params) do
    ActionController::Parameters.new(
      data: data,
      included: included
    )
  end

  let!(:current_user) { User.authenticate!(roles: ["Admin Intake"]) }
  let(:data) do
    {
      type: "HigherLevelReview",
      attributes: attributes
    }
  end

  let(:type) { "ContestableIssue" }
  let(:attributes) do
    {
      receiptDate: formatted_receipt_date,
      informalConference: informal_conference,
      sameOffice: same_office,
      legacyOptInApproved: legacy_opt_in_approved,
      benefitType: benefit_type,
      veteran: { fileNumberOrSsn: file_number_or_ssn }
    }
  end

  let(:receipt_date) { Time.zone.today - 6.days }
  let(:informal_conference) { true }
  let(:same_office) { false }
  let(:legacy_opt_in_approved) { true }
  let(:benefit_type) { "compensation" }
  let(:file_number_or_ssn) { "55555555" }

  let(:formatted_receipt_date) { receipt_date.strftime("%F") }

  let(:included) { [contestable_issue] }

  let(:contestable_issue) do
    {
      type: "ContestableIssue",
      attributes: {
        ratingIssueId: rating_issue_id,
        decisionIssueId: decision_issue_id,
        ratingDecisionIssueId: rating_decision_issue_id
      }
    }
  end

  let(:rating_issue_id) { contestable_issues.first.rating_issue_reference_id }
  let(:decision_issue_id) { contestable_issues.first.decision_issue&.id }
  let(:rating_decision_issue_id) { contestable_issues.first.rating_decision_reference_id }

  let(:contestable_issues) do
    ContestableIssueGenerator.new(
      decision_review_class.new(
        veteran_file_number: veteran.file_number,
        receipt_date: receipt_date,
        benefit_type: benefit_type
      )
    ).contestable_issues
  end

  let(:decision_review_class) { HigherLevelReview }

  let!(:veteran) do
    Generators::Veteran.build(
      file_number: file_number_or_ssn,
      first_name: first_name,
      last_name: last_name
    )
  end

  let(:first_name) { "Samantha" }
  let(:last_name) { "Smith" }

  let!(:rating) { generate_rating(veteran, promulgation_date, profile_date) }

  let(:promulgation_date) { receipt_date - 10.days }
  let(:profile_date) { (receipt_date - 8.days).to_datetime }

  #   before do
  #     Timecop.freeze(post_ama_start_date)
  #
  #     [:establish_claim!, :create_contentions!, :associate_rating_request_issues!].each do |method|
  #       allow(Fakes::VBMSService).to receive(method).and_call_original
  #     end
  #   end

  context do
    it { expect(contestable_issues).not_to be_empty }
  end

  describe "#higher_level_review" do
    it { expect(subject.run!.higher_level_review).to be_a(HigherLevelReview) }
    context do
      let(:request_issues) { subject.run!.higher_level_review.request_issues.to_a }
      let(:request_issue) { request_issues.first }
      it { expect(request_issues).to be_an Array }
      it { expect(request_issues.size).to be 1 }
      it do
        expect(
          "rating_issue_reference_id" => request_issue[:contested_rating_issue_reference_id],
          "rating_issue_diagnostic_code" => request_issue[:contested_rating_issue_diagnostic_code],
          "rating_decision_reference_id" => request_issue[:contested_rating_decision_reference_id],
          #"decision_text" => request_issue[:nonrating_issue_description],
          "is_unidentified" => request_issue[:is_unidentified],
          #"decision_date" => request_issue[:decision_date],
          "benefit_type" => request_issue[:benefit_type],
          "ramp_claim_id" => request_issue[:ramp_claim_id],
          "contested_decision_issue_id" => request_issue[:contested_decision_issue_id]
        ).to eq(
          Api::V3::DecisionReview::ContestableIssueParams.new(
            decision_review_class: HigherLevelReview,
            veteran: veteran,
            receipt_date: receipt_date,
            benefit_type: benefit_type,
            params: contestable_issue
          ).intakes_controller_params.as_json.slice("rating_issue_reference_id", "rating_issue_diagnostic_code", "rating_decision_reference_id", "is_unidentified", "benefit_type", "ramp_claim_id", "contested_decision_issue_id")
        )
      end
    end
  end
end
