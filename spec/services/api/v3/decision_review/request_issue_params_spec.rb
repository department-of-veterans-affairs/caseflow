# frozen_string_literal: true

require "rails_helper"

context Api::V3::DecisionReview::RequestIssueParams do
  let(:benefit_type) { "compensation" }
  let(:all_fields_are_blank) do
    ActionController::Parameters.new(
      type: "RequestIssue",
      attributes: {}
    )
  end
  let(:invalid_category) do
    ActionController::Parameters.new(
      type: "RequestIssue",
      attributes: {
        category: 22,
        ratingIssueId: 1
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
  let(:invalid_legacy_fields_or_no_opt_in) do
    ActionController::Parameters.new(
      type: "RequestIssue",
      attributes: {
        legacyAppealId: "9876543210",
      }
    )
  end

  context ".new" do
    subject { Api::V3::DecisionReview::RequestIssueParams }
    it "should return :request_issue_cannot_be_empty error code" do
      expect(
        subject.new(
          request_issue: all_fields_are_blank,
          benefit_type: benefit_type,
          legacy_opt_in_approved: true
        ).error_code
      ).to eq(:request_issue_cannot_be_empty)
    end
    it "should return :request_issue_category_invalid_for_benefit_type error code" do
      expect(
        subject.new(
          request_issue: invalid_category,
          benefit_type: benefit_type,
          legacy_opt_in_approved: true
        ).error_code
      ).to eq(:request_issue_category_invalid_for_benefit_type)
    end
    it "should return :request_issue_must_have_at_least_one_ID_field error code" do
      expect(
        subject.new(
          request_issue: no_ids,
          benefit_type: benefit_type,
          legacy_opt_in_approved: true
        ).error_code
      ).to eq(:request_issue_must_have_at_least_one_ID_field)
    end
    it "should return :request_issue_legacyAppealIssueId_is_blank_when_legacyAppealId_is_present error code" do
      expect(
        subject.new(
          request_issue: invalid_legacy_fields_or_no_opt_in,
          benefit_type: benefit_type,
          legacy_opt_in_approved: true
        ).error_code
      ).to eq(:request_issue_legacyAppealIssueId_is_blank_when_legacyAppealId_is_present)
    end
  end
end
