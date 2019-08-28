# frozen_string_literal: true

require "rails_helper"

context Api::V3::DecisionReview::IntakeParams do
  let(:veteran_file_number) { "64205050" }
  let(:receipt_date) { (Time.zone.today - 5.days).strftime("%Y-%m-%d") }
  let(:informal_conference) { true }
  let(:same_office) { false }
  let(:legacy_opt_in_approved) { true }
  let(:benefit_type) { "compensation" }
  let(:category) { "Apportionment" }
  let(:decision_issue_id) { "232" }
  let(:decision_date) { (Time.zone.today - 10.days).strftime("%Y-%m-%d") }
  let(:decision_text) { "Some text here." }
  let(:legacy_appeal_id) { -1 }
  let(:legacy_appeal_issue_id) { 0 }
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
  let(:veteran) do
    {
      data: {
        type: "Veteran",
        id: veteran_file_number
      }
    }
  end
  let(:claimant) do
    {
      data: {
        type: "Claimant",
        id: 44,
        meta: {
          payeeCode: "10"
        }
      }
    }
  end
  let(:relationships) do
    {
      veteran: veteran,
      claimant: claimant
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
          category: category,
          decisionIssueId: decision_issue_id,
          decisionDate: decision_date,
          decisionText: decision_text,
          legacyAppealId: legacy_appeal_id,
          legacyAppealIssueId: legacy_appeal_issue_id,
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

  subject { Api::V3::DecisionReview::IntakeParams.new(params) }

  context ".veteran_file_number" do
    it "should return the veteran_file_number given" do
      expect(subject.veteran_file_number).to eq(veteran_file_number)
    end
  end

  context ".review_params" do
    it "should return a properly shape IntakesController-style params object" do
      expect(subject.review_params).to be_a(ActionController::Parameters)
      expect(subject.review_params.as_json).to eq(
        {
          receipt_date: attributes[:receiptDate],
          informal_conference: attributes[:informalConference],
          same_office: attributes[:sameOffice],
          benefit_type: attributes[:benefitType],
          claimant: claimant[:data][:id],
          payee_code: claimant[:data][:meta][:payeeCode],
          veteran_is_not_claimant: true,
          legacy_opt_in_approved: legacy_opt_in_approved
        }.as_json
      )
    end

    context do
      let(:receipt_date) { nil }
      it "should return today's date if no receiptDate was provided" do
        expect(subject.review_params[:receipt_date]).to eq(Time.now.in_time_zone.strftime("%Y-%m-%d"))
      end
    end

    context do
      let(:claimant) { nil }
      it "should return a properly shape IntakesController-style params object" do
        expect(subject.errors).to eq([])
        expect(subject.review_params[:claimant]).to eq(nil)
        expect(subject.review_params[:payee_code]).to eq(nil)
        expect(subject.review_params[:veteran_is_not_claimant]).to eq(false)
      end
    end

    # tweaked for happy path (always returns true)
    context do
      let(:legacy_opt_in_approved) { false }
      it "should return a properly shape IntakesController-style params object" do
        expect(subject.errors).to eq([])
        expect(subject.review_params[:legacy_opt_in_approved]).to eq(true)
      end
    end
  end

  context ".complete_params" do
    it "should return a properly shape IntakesController-style params object" do
      expect(subject.errors).to eq([])
      expect(subject.complete_params.as_json).to eq(
        {
          request_issues: [
            {
              is_unidentified: false,
              benefit_type: benefit_type,
              nonrating_issue_category: category,
              contested_decision_issue_id: decision_issue_id,
              decision_date: decision_date,
              decision_text: decision_text,
              vacols_id: legacy_appeal_id,
              vacols_sequence_id: legacy_appeal_issue_id,
              notes: notes
            }
          ]
        }.as_json
      )
    end
  end

  context ".errors" do
    context "invalid minimum required shape: data isn't a hash" do
      let(:params) { { data: "Hello!" } }
      it "should have code :malformed_request" do
        expect(subject.errors.length).to eq(1)
        expect(subject.errors[0].code).to eq(:malformed_request)
      end
    end

    context "invalid minimum required shape: type" do
      let(:params) { { data: { type: "Possum", attributes: {}, relationships: relationships } } }
      it "should have code :malformed_request" do
        expect(subject.errors.length).to eq(1)
        expect(subject.errors[0].code).to eq(:malformed_request)
      end
    end

    context "valid minimum required shape" do
      let(:params) do
        {
          data: {
            type: "HigherLevelReview",
            attributes: { benefitType: "compensation" },
            relationships: relationships
          }
        }
      end
      it "should have no errors" do
        expect(subject.errors.length).to eq(0)
      end
    end

    context "invalid minimum required shape: veteran type" do
      let(:params) do
        {
          data: {
            type: "HigherLevelReview",
            attributes: {},
            relationships: {
              veteran: {
                data: {
                  type: "Veretan",
                  id: "something"
                }
              }
            }
          }
        }
      end
      it "should have code :malformed_request" do
        expect(subject.errors.length).to eq(1)
        expect(subject.errors[0].code).to eq(:malformed_request)
      end
    end

    context "valid minimum required shape" do
      let(:params) do
        {
          data: {
            type: "HigherLevelReview",
            attributes: { benefitType: "compensation" },
            relationships: {
              veteran: {
                data: {
                  type: "Veteran",
                  id: "something"
                }
              }
            }
          }
        }
      end
      it "should have no errors" do
        expect(subject.errors.length).to eq(0)
      end
    end

    context "invalid minimum required shape: no veteran id" do
      let(:params) do
        {
          data: {
            type: "HigherLevelReview",
            attributes: {},
            relationships: {
              veteran: {
                data: {
                  type: "Veretan",
                  id: " "
                }
              }
            }
          }
        }
      end
      it "should have code :malformed_request" do
        expect(subject.errors.length).to eq(1)
        expect(subject.errors[0].code).to eq(:malformed_request)
      end
    end

    context "bad request issue" do
      let(:included) do
        [
          {
            type: "RequestIssue",
            attributes: {}
          }
        ]
      end
      it "should have code :" do
        expect(subject.errors.length).to eq(1)
        expect(subject.errors[0].code).to eq(:request_issue_cannot_be_empty)
      end
    end

    context "invalid benefit type" do
      let(:benefit_type) { "super powers" }
      it "should have code :invalid_benefit_type" do
        expect(subject.errors.length).to eq(1)
        expect(subject.errors[0].code).to eq(:invalid_benefit_type)
      end
    end
  end
end
