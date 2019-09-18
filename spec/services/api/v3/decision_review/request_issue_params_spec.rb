# frozen_string_literal: true

context Api::V3::DecisionReview::RequestIssueParams do
  let(:bad_shape_not_params) do
    {
      type: "RequestIssue",
      attributes: {
        category: "Incarceration Adjustments",
        ratingIssueId: 400
      }
    }
  end

  let(:bad_shape_wrong_type) do
    ActionController::Parameters.new(
      type: "RequestIshoo",
      attributes: {
        category: "Active Duty Adjustments",
        decisionIssueId: 87
      }
    )
  end

  let(:bad_shape_attributes_does_not_respond_to_has_key) do
    ActionController::Parameters.new(
      type: "RequestIssue",
      attributes: [
        {
          category: "Character of discharge determinations",
          ratingIssueId: 500
        }
      ]
    )
  end

  let(:attributes_blank_1) do
    ActionController::Parameters.new(
      type: "RequestIssue",
      attributes: {}
    )
  end

  let(:attributes_blank_2) do
    ActionController::Parameters.new(
      type: "RequestIssue",
      attributes: {
        category: "",
        ratingIssueId: nil,
        decisionIssueId: false,
        decisionText: "   "
      }
    )
  end

  let(:invalid_category) do
    ActionController::Parameters.new(
      type: "RequestIssue",
      attributes: {
        category: 22,
        ratingIssueId: "12341234123412341234"
      }
    )
  end

  let(:no_ids) do
    ActionController::Parameters.new(
      type: "RequestIssue",
      attributes: {
        category: "Apportionment"
      }
    )
  end

  let(:has_legacyAppealId_but_missing_legacyAppealIssueId) do
    ActionController::Parameters.new(
      type: "RequestIssue",
      attributes: {
        legacyAppealId: "cat"
      }
    )
  end

  let(:has_legacyAppealIssueId_but_missing_legacyAppealId) do
    ActionController::Parameters.new(
      type: "RequestIssue",
      attributes: {
        legacyAppealIssueId: 987_654_321_098_763_210
      }
    )
  end

  let(:good) do
    ActionController::Parameters.new(
      type: "RequestIssue",
      attributes: {
        notes: "Hello there!",
        decisionIssueId: -1,
        ratingIssueId: 0,
        legacyAppealId: "ladybug",
        legacyAppealIssueId: 88.001,
        category: "Character of discharge determinations",
        decisionDate: "a date",
        decisionText: "a text"
      }
    )
  end

  let(:benefit_type) { "compensation" }

  let(:new_request_issue_params) do
    lambda do |request_issue, options = {}|
      Api::V3::DecisionReview::RequestIssueParams.new(
        {
          request_issue: request_issue,
          benefit_type: benefit_type,
          legacy_opt_in_approved: true
        }.merge(options)
      )
    end
  end

  context ".error_code" do
    it "should return :request_issue_malformed" do
      expect(
        new_request_issue_params[bad_shape_not_params].error_code
      ).to eq(:request_issue_malformed)
    end

    it "should return :request_issue_malformed" do
      expect(
        new_request_issue_params[bad_shape_wrong_type].error_code
      ).to eq(:request_issue_malformed)
    end

    it "should return :request_issue_malformed" do
      expect(
        new_request_issue_params[bad_shape_attributes_does_not_respond_to_has_key].error_code
      ).to eq(:request_issue_malformed)
    end

    it "should return :request_issue_cannot_be_empty" do
      expect(
        new_request_issue_params[attributes_blank_1].error_code
      ).to eq(:request_issue_cannot_be_empty)
    end

    it "should return :request_issue_cannot_be_empty" do
      expect(
        new_request_issue_params[attributes_blank_2].error_code
      ).to eq(:request_issue_cannot_be_empty)
    end

    it "should return :request_issue_category_invalid_for_benefit_type" do
      expect(
        new_request_issue_params[invalid_category].error_code
      ).to eq(:request_issue_category_invalid_for_benefit_type)
    end

    it "should return :request_issue_must_have_at_least_one_ID_field" do
      expect(
        new_request_issue_params[no_ids].error_code
      ).to eq(:request_issue_must_have_at_least_one_ID_field)
    end

    it "should return :request_issue_legacyAppealIssueId_is_blank_when_legacyAppealId_is_present" do
      expect(
        new_request_issue_params[has_legacyAppealId_but_missing_legacyAppealIssueId].error_code
      ).to eq(:request_issue_legacyAppealIssueId_is_blank_when_legacyAppealId_is_present)
    end

    it "should return :request_issue_legacyAppealId_is_blank_when_legacyAppealIssueId_is_present" do
      expect(
        new_request_issue_params[has_legacyAppealIssueId_but_missing_legacyAppealId].error_code
      ).to eq(:request_issue_legacyAppealId_is_blank_when_legacyAppealIssueId_is_present)
    end

    it "should return nil" do
      expect(
        new_request_issue_params[good].error_code
      ).to eq(nil)
    end

    it "should return :request_issue_legacy_not_opted_in" do
      expect(
        new_request_issue_params[good, legacy_opt_in_approved: false].error_code
      ).to eq(:request_issue_legacy_not_opted_in)
    end
  end

  context ".intakes_controller_params" do
    it "should return a properly shape IntakesController-style params object" do
      expect(new_request_issue_params[good].intakes_controller_params).to be_a(ActionController::Parameters)
      expect(new_request_issue_params[good].intakes_controller_params.as_json).to eq(
        {
          rating_issue_reference_id: good[:attributes][:ratingIssueId],
          decision_text: good[:attributes][:decisionText],
          decision_date: good[:attributes][:decisionDate],
          nonrating_issue_category: good[:attributes][:category],
          benefit_type: benefit_type,
          notes: good[:attributes][:notes],
          is_unidentified: false,
          vacols_id: good[:attributes][:legacyAppealId],
          vacols_sequence_id: good[:attributes][:legacyAppealIssueId],
          contested_decision_issue_id: good[:attributes][:decisionIssueId]
        }.as_json
      )
    end
  end
end
