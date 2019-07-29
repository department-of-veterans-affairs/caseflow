# frozen_string_literal: true

require "rails_helper"

describe Api::V3::HigherLevelReviewPreintake do
  context "contests on_file_decision" do
    it "should work with valid hash" do
      hlr = Api::V3::HigherLevelReviewPreintake.new(
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
                "id" => "55555555"
              }
            },
            "claimant" => {
              "data" => {
                "type" => "Claimant",
                "id" => "44444444",
                "meta" => {
                  "payeeCode" => "10"
                }
              }
            }
          }
        },
        "included" => [
          {
            "type" => "request_issue",
            "attributes" => {
              "contests" => "on_file_decision",
              "decision_id" => "32",
              "notes" => "disputing amount"
            }
          },
          {
            "type" => "request_issue",
            "attributes" => {
              "contests" => "on_file_rating",
              "rating_id" => "44",
              "notes" => "disputing disability percent"
            }
          },
          {
            "type" => "request_issue",
            "attributes" => {
              "contests" => "on_file_legacy_issue",
              "legacy_id" => "32abc",
              "notes" => "bad knee"
            }
          },
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
      )
      expect(hlr.benefit_type).to be "pension"
    end
  end
end
