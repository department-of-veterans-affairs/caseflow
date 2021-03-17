# frozen_string_literal: true

require "support/intake_helpers"

describe Api::V3::DecisionReviews::IntakeProcessor, :all_dbs do
  include IntakeHelpers

  subject do
    Api::V3::DecisionReviews::IntakeProcessor.new(
      form_type: form_type,
      params_class: params_class,
      user: user,
      params: params
    )
  end

  let(:form_type) { "higher_level_review" }
  let(:params_class) { Api::V3::DecisionReviews::HigherLevelReviewIntakeParams }
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

  context "contestable_issues" do
    it { expect(contestable_issues).not_to be_empty }
  end

  context ".new" do
    it "should begin an intake" do
      expect(subject.intake).to be_a(Intake)
    end

    it "the intake should not have a \"detail\" yet" do
      expect(subject.intake.detail).to be_nil
    end

    it "should have no errors" do
      expect(subject.errors).to eq []
      expect(subject.errors?).to be false
    end
  end

  context "#run!" do
    let(:form_type) { "higher_level_review" }
    it "given form_type \"higher_level_review\", should create a HigherLevelReview" do
      expect(subject.run!.intake.detail).to be_a(HigherLevelReview)
    end

    it "the HigherLevelReview should have a uuid" do
      expect(subject.run!.uuid).to be_truthy
    end
  end
end
