# frozen_string_literal: true

require "support/intake_helpers"

describe Api::V3::DecisionReview::IntakeProcessor, :all_dbs do
  include IntakeHelpers

  before do
    Timecop.freeze(post_ama_start_date)

    [:establish_claim!, :create_contentions!, :associate_rating_request_issues!].each do |method|
      allow(Fakes::VBMSService).to receive(method).and_call_original
    end
  end

  let(:file_number_or_ssn) { "55555555" }
  let!(:veteran) do
    Generators::Veteran.build(file_number: file_number_or_ssn,
                              first_name: "Boo",
                              last_name: "Radley")
  end
  let!(:rating) { generate_rating(veteran, promulgation_date, profile_date) }

  let!(:current_user) do
    User.authenticate!(roles: ["Admin Intake"])
  end

  let(:receipt_date) { Time.zone.today - 6.days }
  let(:promulgation_date) { receipt_date - 10.days }
  let(:profile_date) { (receipt_date - 8.days).to_datetime }

  let(:informal_conference) { true }
  let(:same_office) { false }
  let(:legacy_opt_in_approved) { true }
  let(:benefit_type) { "compensation" }
  let(:attributes) do
    {
      receiptDate: receipt_date.strftime("%F"),
      informalConference: informal_conference,
      sameOffice: same_office,
      legacyOptInApproved: legacy_opt_in_approved,
      benefitType: benefit_type,
      veteran: {
        fileNumberOrSsn: file_number_or_ssn
      }
    }
  end

  let(:data) do
    {
      type: "HigherLevelReview",
      attributes: attributes
    }
  end

  let(:rating_issue_id) { "123" }
  let(:included) do
    [
      {
        type: "ContestableIssue",
        attributes: {
          ratingIssueId: rating_issue_id
        }
      }
    ]
  end

  let(:params) do
    ActionController::Parameters.new(
      data: data,
      included: included
    )
  end

  let(:form_type) { "higher_level_review" }

  subject do
    Api::V3::DecisionReview::IntakeProcessor
      .new(params: params, user: current_user, form_type: form_type)
  end

  context ".new" do
    it "should begin an intake" do
      expect(subject.intake).to be_a(Intake)
    end

    it "the intake should not have a \"detail\" yet" do
      expect(subject.intake.detail).to be_nil
    end

    it "should have no errors" do
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
