# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

describe Api::V3::HigherLevelReviewProcessor, :all_dbs do
  let(:user) { Generators::User.build }
  let(:veteran_file_number) { "64205050" }
  let!(:veteran) { Generators::Veteran.build(file_number: veteran_file_number, country: "USA") }
  #   let!(:claimant) do
  #     Claimant.create!(
  #       decision_review: higher_level_review,
  #       participant_id: veteran.participant_id,
  #       payee_code: "10"
  #     )
  #   end

  let(:receipt_date) { "2019-07-10" }
  let(:informal_conference) { true }
  let(:same_office) { false }
  let(:legacy_opt_in_approved) { true }
  let(:benefit_type) { "pension" }

  let(:params) do
    ActionController::Parameters.new(
      data: {
        type: "HigherLevelReview",
        attributes: {
          receiptDate: receipt_date,
          informalConference: informal_conference,
          sameOffice: same_office,
          legacyOptInApproved: legacy_opt_in_approved,
          benefitType: benefit_type
        },
        relationships: {
          veteran: {
            data: {
              type: "Veteran",
              id: veteran_file_number
            }
          }
        }
      },
      "included" => [
        # {
        #   "type" => "request_issue",
        #   "attributes" => {
        #     "contests" => "on_file_decision_issue",
        #     "decision_id" => "32",
        #     "notes" => "disputing amount"
        #   }
        # },
        # {
        #   "type" => "request_issue",
        #   "attributes" => {
        #     "contests" => "on_file_rating_issue",
        #     "rating_id" => "44",
        #     "notes" => "disputing disability percent"
        #   }
        # },
        # {
        #   "type" => "request_issue",
        #   "attributes" => {
        #     "contests" => "on_file_legacy_issue",
        #     "legacy_id" => "32abc",
        #     "notes" => "bad knee"
        #   }
        # },
        {
          type: "request_issue",
          attributes: {
            contests: "other",
            category: "Penalty Period",
            decision_date: "2020-10-10",
            decision_text: "Some text here.",
            notes: "not sure if this is on file"
          }
        }
      ]
    )
  end

  context "new" do
    subject { Api::V3::HigherLevelReviewProcessor.new(params, user) }

    it "no errors" do
      puts params.as_json
      expect(subject.review_params).to eq(
        ActionController::Parameters.new(
          informal_conference: informal_conference,
          same_office: same_office,
          benefit_type: benefit_type,
          receipt_date: receipt_date,
          claimant: nil,
          veteran_is_not_claimant: false,
          payee_code: nil,
          legacy_opt_in_approved: legacy_opt_in_approved
        )
      )
    end
  end
end
