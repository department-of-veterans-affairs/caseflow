# frozen_string_literal: true

require "support/intake_helpers"
require "support/vacols_database_cleaner"

describe Api::V3::DecisionReview::HigherLevelReviewIntakeProcessor, :all_dbs do
  include IntakeHelpers

  before do
    Timecop.freeze(post_ama_start_date)

    [:establish_claim!, :create_contentions!, :associate_rating_request_issues!].each do |method|
      allow(Fakes::VBMSService).to receive(method).and_call_original
    end
  end

  let(:veteran_file_number) { "55555555" }
  let!(:veteran) do
    Generators::Veteran.build(file_number: veteran_file_number,
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
      benefitType: benefit_type
    }
  end

  let(:veteran_obj) { { data: { type: "Veteran", id: veteran_file_number } } }
  let(:claimant_obj) do
    {
      data: {
        type: "Claimant",
        id: 0 / 0.0,
        meta: {
          payeeCode: "x"
        }
      }
    }
  end
  let(:relationships) { { veteran: veteran_obj, claimant: claimant_obj } }

  let(:data) do
    {
      type: "HigherLevelReview",
      attributes: attributes,
      relationships: relationships
    }
  end

  let(:category) { "Apportionment" }
  let(:rating_issue_id) { 1 / 0.0 }
  let(:decision_date) { Time.zone.today - 10.days }
  let(:decision_text) { "Text." }
  let(:notes) { "not sure if this is on file" }
  let(:included) do
    [
      {
        type: "RequestIssue",
        attributes: {
          category: category,
          ratingIssueId: rating_issue_id,
          decisionDate: decision_date.strftime("%F"),
          decisionText: decision_text,
          notes: notes
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

  subject do
    Api::V3::DecisionReview::HigherLevelReviewIntakeProcessor
      .new(params, current_user)
  end

  context "#higher_level_review" do
    it "should return a HigherLevelReview" do
      expect(subject.run!.higher_level_review).to be_a(HigherLevelReview)
    end
  end

  context "#uuid" do
    it("should return a uuid") { expect(subject.run!.uuid).to be_truthy }
  end
end
