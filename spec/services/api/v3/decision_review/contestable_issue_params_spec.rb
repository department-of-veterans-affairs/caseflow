# frozen_string_literal: true

context Api::V3::DecisionReview::ContestableIssueParams do
  let(:contestable_issue_params) do
    Api::V3::DecisionReview::ContestableIssueParams.new(
      benefit_type: benefit_type,
      legacy_opt_in_approved: legacy_opt_in_approved,
      params: params
    )
  end

  let(:benefit_type) { "compensation" }
  let(:legacy_opt_in_approved) { true }

  let(:params) do
    ActionController::Parameters.new(
      type: "ContestableIssue",
      attributes: attributes
    )
  end

  let(:attributes) do
    {
      decisionIssueId: decision_issue_id,
      ratingIssueId: rating_issue_id,
      ratingDecisionIssueId: rating_decision_issue_id,
      legacyAppealIssues: legacy_appeal_issues
    }
  end

  let(:decision_issue_id) { 123 }
  let(:rating_issue_id) { "456" }
  let(:rating_decision_issue_id) { "789" }

  let(:legacy_appeal_issues) do
    [
      {
        legacyAppealId: vacols_id,
        legacyAppealIssueId: vacols_sequence_id
      }
    ]
  end

  let(:vacols_id) { "135" }
  let(:vacols_sequence_id) { "246" }

  describe "#error_code" do
    subject { contestable_issue_params.error_code }

    it { is_expected.to be nil }

    describe "constestable issue without IDs" do
      let(:decision_issue_id) { nil }
      let(:rating_issue_id) { nil }
      let(:rating_decision_issue_id) { nil }

      it { is_expected.to eq :contestable_issue_cannot_be_empty }

      context do
        let(:rating_issue_id) { "something" }
        it { is_expected.to eq nil }
      end
    end

    describe "legacy appeals not opted in" do
      let(:legacy_opt_in_approved) { false }
      it { is_expected.to eq :must_opt_in_to_associate_legacy_issues }
    end
  end

  context "#intakes_controller_params" do
    subject { contestable_issue_params.intakes_controller_params.as_json }

    it do
      is_expected.to eq(
        {
          benefit_type: benefit_type,
          vacols_id: attributes[:legacyAppealIssues][0][:legacyAppealId],
          vacols_sequence_id: attributes[:legacyAppealIssues][0][:legacyAppealIssueId],
          is_unidentified: false,
          contested_decision_issue_id: attributes[:decisionIssueId],
          rating_issue_reference_id: attributes[:ratingIssueId],
          rating_decision_reference_id: attributes[:ratingDecisionIssueId]
        }.as_json
      )
    end
  end
end
