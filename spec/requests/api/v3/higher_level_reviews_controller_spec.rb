# frozen_string_literal: true

require "rails_helper"
require "support/intake_helpers"
require "support/vacols_database_cleaner"
require File.expand_path("../../../../app/services/api/v3/higher_level_review_processor.rb", __dir__)

describe Api::V3::DecisionReview::HigherLevelReviewsController, :all_dbs, type: :request do
  context "#intake_status" do
    let(:uuid) { 444 }
    let(:asyncable_status) { "nice" }
    let(:higher_level_review) do
      Struct.new(:uuid, :asyncable_status).new(uuid, asyncable_status)
    end

    subject { Api::V3::DecisionReview::HigherLevelReviewsController.intake_status(higher_level_review) }
    it "should return the correct hash" do
      expect(subject).to eq(
        data: {
          type: "IntakeStatus",
          id: uuid,
          attributes: {
            status: asyncable_status
          }
        }
      )
    end
  end

  context "#errors_to_render_args" do
    let(:error_from_error_code) { Api::V3::HigherLevelReviewProcessor.method(:error_from_error_code) }
    let(:error_a) { error_from_error_code.call(:veteran_not_found) }
    let(:error_b) { error_from_error_code.call(nil) }

    subject { Api::V3::DecisionReview::HigherLevelReviewsController.method(:errors_to_render_args) }
    it "should return the correct json" do
      expect(subject.call([error_a, error_b])).to eq(
        json: {
          errors:
            [
              error_a,
              error_b
            ]
        },
        status: 422
      )
    end
  end

  context "#error_from_objects_error_code" do
    let(:error_from_error_code) { Api::V3::HigherLevelReviewProcessor.method(:error_from_error_code) }
    let(:code_a) { :incident_flash }
    let(:object_a) do
      Intake.new(error_code: code_a)
    end
    let(:code_b) { :invalid_file_number }
    let(:object_b) do
      Api::V3::HigherLevelReviewProcessor::StartError.new(Intake.new(error_code: code_b))
    end

    subject { Api::V3::DecisionReview::HigherLevelReviewsController.method(:error_from_objects_error_code) }
    it "should return the correct error" do
      expect(subject.call(object_a, object_b)).to eq(error_from_error_code.call(code_a))
      expect(subject.call(object_b, object_a)).to eq(error_from_error_code.call(code_b))
    end
  end
end

describe Api::V3::DecisionReview::HigherLevelReviewsController, :all_dbs, type: :request do
  #   describe "#mock_create" do
  #     it "should return a 202 on success" do
  #       post "/api/v3/decision_review/higher_level_reviews"
  #       expect(response).to have_http_status(202)
  #     end
  #     it "should be a jsonapi IntakeStatus response" do
  #       post "/api/v3/decision_review/higher_level_reviews"
  #       json = JSON.parse(response.body)
  #       expect(json["data"].keys).to include("id", "type", "attributes")
  #       expect(json["data"]["type"]).to eq "IntakeStatus"
  #       expect(json["data"]["attributes"]["status"]).to be_a String
  #     end
  #     it "should include a Content-Location header" do
  #       post "/api/v3/decision_review/higher_level_reviews"
  #       expect(response.headers.keys).to include("Content-Location")
  #       expect(response.headers["Content-Location"]).to match(
  # "/api/v3/decision_review/higher_level_reviews/intake_status")
  #     end
  #   end

  include IntakeHelpers

  before do
    Timecop.freeze(post_ama_start_date)

    allow(Fakes::VBMSService).to receive(:establish_claim!).and_call_original
    allow(Fakes::VBMSService).to receive(:create_contentions!).and_call_original
    allow(Fakes::VBMSService).to receive(:associate_rating_request_issues!).and_call_original
  end

  let(:veteran_file_number) { "123412345" }

  let!(:veteran) do
    Generators::Veteran.build(file_number: veteran_file_number,
                              first_name: "Ed",
                              last_name: "Merica")
  end

  let(:promulgation_date) { receipt_date - 10.days }

  let!(:current_user) do
    User.authenticate!(roles: ["Admin Intake"])
  end

  let(:profile_date) { (receipt_date - 8.days).to_datetime }

  let!(:rating) do
    Generators::Rating.build(
      participant_id: veteran.participant_id,
      promulgation_date: promulgation_date,
      profile_date: profile_date,
      issues: [
        { reference_id: "abc123", decision_text: "Left knee granted" },
        { reference_id: "def456", decision_text: "PTSD denied" },
        { reference_id: "def789", decision_text: "Looks like a VACOLS issue" }
      ]
    )
  end

  let(:receipt_date) { Time.zone.today - 5.days }
  let(:informal_conference) { true }
  let(:same_office) { false }
  let(:legacy_opt_in_approved) { true }
  let(:benefit_type) { "pension" }
  let(:contests) { "other" }
  let(:category) { "Penalty Period" }
  let(:decision_date) { Time.zone.today - 10.days }
  let(:decision_text) { "Some text here." }
  let(:notes) { "not sure if this is on file" }
  let(:attributes) do
    {
      receiptDate: receipt_date.strftime("%Y-%m-%d"),
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
          decision_date: decision_date.strftime("%Y-%m-%d"),
          decision_text: decision_text,
          notes: notes
        }
      }
    ]
  end
  let(:params) do
    {
      data: data,
      included: included
    }
  end

  describe "#create" do
    it "should return a 202 on success" do
      post("/api/v3/decision_review/higher_level_reviews",
           params: params)
      expect(response).to have_http_status(202)
    end
  end
end
