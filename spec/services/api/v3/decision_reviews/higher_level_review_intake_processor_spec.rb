# frozen_string_literal: true

require "support/intake_helpers"

describe Api::V3::DecisionReviews::IntakeProcessor, :all_dbs do
  include IntakeHelpers

  subject { Api::V3::DecisionReviews::HigherLevelReviewIntakeProcessor.new(params, user) }

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
      veteran: { ssn: ssn }
    }
  end

  let(:receipt_date) { Time.zone.today - 6.days }
  let(:informal_conference) { false }
  let(:same_office) { false }
  let(:legacy_opt_in_approved) { true }
  let(:benefit_type) { "compensation" }
  let(:ssn) { "555555555" }

  let(:formatted_receipt_date) { receipt_date.strftime("%F") }

  let(:included) { [contestable_issue] }

  let(:contestable_issue) do
    {
      type: "ContestableIssue",
      attributes: {
        issue: "Right Knee",
        decisionDate: "2020-04-01",
        ratingIssueReferenceId: rating_issue_id
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

  let(:veteran) do
    create(:veteran,
           ssn: ssn,
           first_name: first_name,
           last_name: last_name)
  end

  let(:first_name) { "Samantha" }
  let(:last_name) { "Smith" }

  let!(:rating) { generate_rating(veteran, promulgation_date, profile_date) }

  let(:promulgation_date) { receipt_date - 10.days }
  let(:profile_date) { (receipt_date - 8.days).to_datetime }

  context do
    it { expect(contestable_issues).not_to be_empty }
  end

  describe "#higher_level_review" do
    it { expect(subject.run!.higher_level_review).to be_a(HigherLevelReview) }

    context(
      "ensure that, after the HLR processor has run," \
      " given only IDs to identify a contestable issue," \
      " it correctly filled in the other fields"
    ) do
      let(:request_issues) { subject.run!.higher_level_review.request_issues.to_a }
      let(:request_issue) { request_issues.first }

      it { expect(request_issues).to be_an Array }

      it { expect(request_issues.size).to be 1 }

      it { expect(request_issue[:contested_issue_description]).not_to be nil }
      it { expect(request_issue[:decision_date].strftime("%F")).not_to be nil }
    end
  end
end
