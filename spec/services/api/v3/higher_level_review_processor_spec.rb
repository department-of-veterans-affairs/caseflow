# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

describe Intake, :all_dbs do
  before do
    RequestStore[:current_user] = user
  end

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

  let(:params) do
    {
      "data" => {
        "type" => "HigherLevelReview",
        "attributes" => {
          "receiptDate" => "2019-07-10",
          "informalConference" => true,
          "sameOffice" => false,
          "legacyOptInApproved" => true,
          "benefitType" => "pension"
        },
        "relationships" => {
          "veteran" => {
            "data" => {
              "type" => "Veteran",
              "id" => veteran_file_number
            }
          }
        }
      },
      "included" => [
        #         {
        #           "type" => "request_issue",
        #           "attributes" => {
        #             "contests" => "on_file_decision_issue",
        #             "decision_id" => "32",
        #             "notes" => "disputing amount"
        #           }
        #         },
        #         {
        #           "type" => "request_issue",
        #           "attributes" => {
        #             "contests" => "on_file_rating_issue",
        #             "rating_id" => "44",
        #             "notes" => "disputing disability percent"
        #           }
        #         },
        #         {
        #           "type" => "request_issue",
        #           "attributes" => {
        #             "contests" => "on_file_legacy_issue",
        #             "legacy_id" => "32abc",
        #             "notes" => "bad knee"
        #           }
        #         },
        {
          "type" => "request_issue",
          "attributes" => {
            "contests" => "other",
            "category" => "Penalty Period",
            "decision_date" => "2020-10-10",
            "decision_text" => "Some text here.",
            "notes" => "not sure if this is on file"
          }
        }
      ]
    }
  end

  context "new" do
    subject { Api::V3::HigherLevelReviewProcessor.new(user: user, params: params) }

    context "when form_type is supported" do
      it "no errors" do
        expect { subject.errors? }.to be false
      end
    end
  end
end
