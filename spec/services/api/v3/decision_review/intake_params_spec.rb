# frozen_string_literal: true

require "rails_helper"

context Api::V3::DecisionReview::IntakeParams do
  let(:params) do
    ActionController::Parameters.new(
      "data" => {
        "type" => "HigherLevelReview",
        "attributes" => {
          "receiptDate" => "2019-07-10",
          "informalConference" => true,
          "sameOffice" => false,
          "legacyOptInApproved" => true,
          "benefitType" => "compensation"
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
          "type" => "RequestIssue",
          "attributes" => {
            "decisionText" => "veteran status verified",
            "decisionDate" => "2019-07-11",
            "category" => "Apportionment"
          }
        },
        {
          "type" => "RequestIssue",
          "attributes" => {
            "decisionIssueId" => 22
          }
        },
        {
          "type" => "RequestIssue",
          "attributes" => {
            "ratingIssueId" => "12345678",
            "legacyAppealId" => "9876543210",
            "legacyAppealIssueId" => 1
          }
        }
      ]
    )
  end

  context ".new" do
    subject { Api::V3::DecisionReview::IntakeParams }
    it "should not raise" do
      expect { subject.new(params) }.not_to raise_error
    end
  end
end 
