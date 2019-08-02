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
  let(:attributes) do
    {
      receiptDate: receipt_date,
      informalConference: informal_conference,
      sameOffice: same_office,
      legacyOptInApproved: legacy_opt_in_approved,
      benefitType: benefit_type
    }
  end
  let(:relationships) do
    {
      veteran: {
        data: {
          type: "Veteran",
          id: veteran_file_number
        }
      }
    }
  end
  let(:data) do
    {
      type: "HigherLevelReview",
      attributes: attributes,
      relationships: relationships
    }
  end
  let(:included) do
    [
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
  end
  let(:params) do
    ActionController::Parameters.new(
      data: data,
      included: included
    )
  end

  context "review_params" do
    subject { Api::V3::HigherLevelReviewProcessor.new(params, user) }
    it "returns the request issue as a properly formatted intake data hash" do
      expect(subject.errors?).to be(false)
      expect(subject.errors).to eq([])

      complete_params = subject.complete_params
      expect(complete_params).to be_a(ActionController::Parameters)

      request_issues = complete_params[:request_issues]
      expect(request_issues).to be_a(Array)

      first = request_issues.first
      expect(first.as_json).to be_a(Hash)
      expect(first.keys.length).to be(6)
      expect(first[:is_unidentified]).to be(false)
      expect(first[:benefit_type]).to be(benefit_type)
      expect(first[:nonrating_issue_category]).to be(category)
      expect(first[:decision_text]).to be(decision_text)
      expect(first[:decision_date]).to be(decision_date)
      expect(first[:notes]).to be(notes)
    end
  end

  context "review_params" do
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

    let(:included) do
      [
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
    end
    subject { Api::V3::HigherLevelReviewProcessor.new(params, user) }
    it "the values returned by complete_params should match those passed into new" do
      expect(subject.errors?).to be(false)
      expect(subject.errors).to eq([])

      complete_params = subject.complete_params
      expect(complete_params).to be_a(ActionController::Parameters)

      request_issues = complete_params[:request_issues]
      expect(request_issues).to be_a(Array)

      a, b, c, d, e = request_issues

      expect(a.as_json).to be_a(Hash)
      expect(a.keys.length).to be(4)
      expect(a[:is_unidentified]).to be(false)
      expect(a[:benefit_type]).to be(benefit_type)
      expect(a[:contested_decision_issue_id]).to be(a_id)
      expect(a[:notes]).to be(a_notes)

      expect(b.as_json).to be_a(Hash)
      expect(b.keys.length).to be(4)
      expect(b[:is_unidentified]).to be(false)
      expect(b[:benefit_type]).to be(benefit_type)
      expect(b[:rating_issue_reference_id]).to be(b_id)
      expect(b[:notes]).to be(b_notes)

      expect(c.as_json).to be_a(Hash)
      expect(c.keys.length).to be(4)
      expect(c[:is_unidentified]).to be(false)
      expect(c[:benefit_type]).to be(benefit_type)
      expect(c[:vacols_id]).to be(c_id)
      expect(c[:notes]).to be(c_notes)

      expect(d.as_json).to be_a(Hash)
      expect(d.keys.length).to be(6)
      expect(d[:is_unidentified]).to be(false)
      expect(d[:benefit_type]).to be(benefit_type)
      expect(d[:nonrating_issue_category]).to be(d_category)
      expect(d[:notes]).to be(d_notes)
      expect(d[:decision_text]).to be(d_decision_text)
      expect(d[:decision_date]).to be(d_decision_date)

      expect(e.as_json).to be_a(Hash)
      expect(e.keys.length).to be(5)
      expect(e[:is_unidentified]).to be(true)
      expect(e[:benefit_type]).to be(benefit_type)
      expect(e[:notes]).to be(e_notes)
      expect(e[:decision_text]).to be(e_decision_text)
      expect(e[:decision_date]).to be(e_decision_date)
    end
  end
end

#   let!(:claimant) do
#     Claimant.create!(
#       decision_review: higher_level_review,
#       participant_id: veteran.participant_id,
#       payee_code: "10"
#     )
#   end
