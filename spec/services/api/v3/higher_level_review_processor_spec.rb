# frozen_string_literal: true

require "support/vacols_database_cleaner"
require "rails_helper"

describe Api::V3::HigherLevelReviewProcessor, :all_dbs do
  let(:user) { Generators::User.build }
  let(:veteran_file_number) { "64205050" }
  let!(:veteran) { Generators::Veteran.build(file_number: veteran_file_number, country: "USA") }
  let(:receipt_date) { "2019-07-10" }
  let(:informal_conference) { true }
  let(:same_office) { false }
  let(:legacy_opt_in_approved) { true }
  let(:benefit_type) { "pension" }
  let(:contests) { "other" }
  let(:category) { "Penalty Period" }
  let(:decision_date) { "2020-10-10" }
  let(:decision_text) { "Some text here." }
  let(:notes) { "not sure if this is on file" }
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
        {
          type: "RequestIssue",
          attributes: {
            contests: contests,
            category: category,
            decision_date: decision_date,
            decision_text: decision_text,
            notes: notes
          }
        }
      ]
    )
  end

  context "review_params and complete_params" do
    subject { Api::V3::HigherLevelReviewProcessor.new(params, user) }

    it "the values returned by review_params should match those passed into new" do
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
    it "the values returned by complete_params should match those passed into new" do
      expect(subject.complete_params).to eq(
        ActionController::Parameters.new(
          request_issues: [
            {
              rating_issue_reference_id: nil,
              rating_issue_diagnostic_code: nil,
              decision_text: decision_text,
              decision_date: decision_date,
              nonrating_issue_category: category,
              benefit_type: benefit_type,
              notes: notes,
              is_unidentified: false,
              untimely_exemption: nil,
              untimely_exemption_notes: nil,
              ramp_claim_id: nil,
              vacols_id: nil,
              vacols_sequence_id: nil,
              contested_decision_issue_id: nil,
              ineligible_reason: nil,
              ineligible_due_to_id: nil,
              edited_description: nil,
              correction_type: nil
            }
          ]
        )
      )
    end
  end

  context "review_params and complete_params" do
    let(:a_contests) { "on_file_decision_issue" }
    let(:a_id) { 232 }
    let(:a_notes) { "Notes for request issue Aaayyyyyy!" }

    let(:b_contests) { "on_file_rating_issue" }
    let(:b_id) { 616 }
    let(:b_notes) { "Notes for request issue BeEeEe!" }

    let(:c_contests) { "on_file_legacy_issue" }
    let(:c_id) { 111_111 }
    let(:c_notes) { "Notes for request issue Sea!" }

    let(:benefit_type) { "compensation" }
    let(:d_contests) { "other" }
    let(:d_category) { "Character of discharge determinations" }
    let(:d_notes) { "Notes for request issue Deee!" }
    let(:d_decision_date) { "2019-05-07" }
    let(:d_decision_text) { "Decision text for request issue Deee!" }

    let(:e_contests) { "other" }
    let(:e_notes) { "Notes for request issue EEEEEEEEEEEEEEE   EEEEE!" }
    let(:e_decision_date) { "2019-05-09" }
    let(:e_decision_text) { "Decision text for request issue EEE!" }

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
          {
            type: "RequestIssue",
            attributes: {
              contests: a_contests,
              id: a_id,
              notes: a_notes
            }
          },
          {
            type: "RequestIssue",
            attributes: {
              contests: b_contests,
              id: b_id,
              notes: b_notes
            }
          },
          {
            type: "RequestIssue",
            attributes: {
              contests: c_contests,
              id: c_id,
              notes: c_notes
            }
          },
          {
            type: "RequestIssue",
            attributes: {
              contests: d_contests,
              category: d_category,
              decision_date: d_decision_date,
              decision_text: d_decision_text,
              notes: d_notes
            }
          },
          {
            type: "RequestIssue",
            attributes: {
              contests: e_contests,
              decision_date: e_decision_date,
              decision_text: e_decision_text,
              notes: e_notes
            }
          }
        ]
      )
    end

    subject { Api::V3::HigherLevelReviewProcessor.new(params, user) }
    it "the values returned by complete_params should match those passed into new" do
      puts subject.complete_params
    end
  end
end

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

#   let!(:claimant) do
#     Claimant.create!(
#       decision_review: higher_level_review,
#       participant_id: veteran.participant_id,
#       payee_code: "10"
#     )
#   end
