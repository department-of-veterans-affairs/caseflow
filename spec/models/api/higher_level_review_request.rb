# coding: utf-8
# frozen_string_literal: true

require "rails_helper"

describe HigherLevelReviewRequest do
  context "test various methods" do
    subject do
      HigherLevelReviewRequest .new(
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
              "type" => "nonrating_issue",
              "attributes" => {
                "decisionText" => "veteran status verified",
                "decisionDate" => "2019-07-11",
                "nonratingIssueCategory" => "Eligibility | Veteran Status"
              }
            },
            {
              "type" => "rating_issue",
              "id" => "def456"
            }
          ]
        }


      )
    end

    it "should have a receipt_date" do
      expect(subject.receipt_date).to eq("2019-07-10")
    end
  end
end
