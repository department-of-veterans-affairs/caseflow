# frozen_string_literal: true

context Api::V3::DecisionReviews::ContestableIssueParams, :all_dbs do
  include IntakeHelpers

  let(:contestable_issue_params) do
    Api::V3::DecisionReviews::ContestableIssueParams.new(
      decision_review_class: decision_review_class,
      veteran: veteran,
      receipt_date: receipt_date,
      benefit_type: benefit_type,
      params: params
    )
  end

  let(:decision_review_class) { HigherLevelReview }
  let!(:veteran) do
    Generators::Veteran.build(
      file_number: file_number,
      first_name: first_name,
      last_name: last_name
    )
  end
  let(:receipt_date) { Time.zone.today - 6.days }
  let(:benefit_type) { "compensation" }
  let(:params) do
    ActionController::Parameters.new(
      type: "ContestableIssue",
      attributes: attributes
    )
  end

  let(:file_number) { "55555555" }
  let(:first_name) { "Jane" }
  let(:last_name) { "Doe" }

  let(:attributes) do
    {
      ratingIssueReferenceId: contestable_issues.first.rating_issue_reference_id,
      decisionIssueId: contestable_issues.first.decision_issue&.id,
      ratingDecisionReferenceId: contestable_issues.first.rating_decision_reference_id
    }
  end

  let(:promulgation_date) { receipt_date - 10.days }
  let(:profile_date) { (receipt_date - 8.days).to_datetime }
  let!(:rating) { generate_rating(veteran, promulgation_date, profile_date) }

  let(:contestable_issues) do
    ContestableIssueGenerator.new(
      decision_review_class.new(
        veteran_file_number: veteran.file_number,
        receipt_date: receipt_date,
        benefit_type: benefit_type
      )
    ).contestable_issues
  end

  describe "#contestable_issue" do
    subject { contestable_issue_params.contestable_issue.as_json }

    it { is_expected.to eq contestable_issues.first.as_json }
    it { is_expected.not_to eq contestable_issues.second.as_json }
  end

  describe "#error_code" do
    subject { contestable_issue_params.error_code }

    it { is_expected.to be nil }

    context "contestable issue without IDs" do
      let(:attributes) { {} }
      it { is_expected.to eq :contestable_issue_params_must_have_ids }
    end

    context "bogus id" do
      let(:attributes) { { decisionIssueId: 0 } }
      it { is_expected.to eq :could_not_find_contestable_issue }
    end
  end

  describe "#unidentified?" do
    subject { contestable_issue_params.unidentified? }

    it { is_expected.to be false }

    context do
      let(:attributes) { {} }
      it { is_expected.to be true }
    end
    context do
      let(:attributes) { { ratingDecisionReferenceId: 0 } }
      it { is_expected.to be false }
    end
  end

  describe "#intakes_controller_params" do
    subject { contestable_issue_params.intakes_controller_params.as_json }

    it do
      is_expected.to eq(
        {
          rating_issue_reference_id: contestable_issues.first&.rating_issue_reference_id,
          rating_issue_diagnostic_code: contestable_issues.first&.rating_issue_diagnostic_code,
          rating_decision_reference_id: contestable_issues.first&.rating_decision_reference_id,
          decision_text: contestable_issues.first&.description,
          is_unidentified: contestable_issue_params.unidentified?,
          decision_date: contestable_issues.first&.approx_decision_date,
          benefit_type: benefit_type,
          ramp_claim_id: contestable_issues.first&.ramp_claim_id,
          contested_decision_issue_id: contestable_issues.first&.decision_issue&.id

        }.as_json
      )
    end
  end
end
