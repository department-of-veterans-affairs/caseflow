# frozen_string_literal: true

require "rails_helper"
require "support/intake_helpers"
require "support/vacols_database_cleaner"
require File.expand_path("../../../../app/services/api/v3/higher_level_review_processor.rb", __dir__)

hlrp = Api::V3::HigherLevelReviewProcessor
hlrc = Api::V3::DecisionReview::HigherLevelReviewsController

describe hlrc do
  context ".intake_status" do
    it "should return a properly formatted IntakeStatus hash" do
      uuid = 444
      asyncable_status = "nice"
      higher_level_review = Struct.new(:uuid, :asyncable_status).new(uuid, asyncable_status)
      expect(hlrc.intake_status(higher_level_review)).to eq(
        data: {
          type: "IntakeStatus",
          id: uuid,
          attributes: {
            status: asyncable_status
          }
        }
      )
    end
    it "should raise a NoMethod error when given an object with neither a uuid nor a asyncable_status method" do
      expect { hlrc.intake_status("") }.to raise_error(NoMethodError)
    end
  end

  context ".errors_to_render_args" do
    it "should return NoMethodError when given something that can't be mapped (or is a filled hash)" do
      [nil, false, "abc", 32, { a: hlrp::Error.new(1000, :something, "Something.") }].each do |errors|
        expect { hlrc.errors_to_render_args(errors) }.to raise_error(NoMethodError)
      end
    end

    it "should return ArgumentError when given an empty hash" do
      expect { hlrc.errors_to_render_args({}) }.to raise_error(ArgumentError)
    end

    let(:error_with_403_integer_status) { hlrp.error_from_error_code(:veteran_not_accessible) }
    let(:error_with_404_integer_status) { hlrp.error_from_error_code(:veteran_not_found) }
    let(:error_with_1000_integer_status) { hlrp::Error.new(1000, :something, "Something.") }
    let(:error_with_403_string_status) { hlrp::Error.new("403", :something_else, "Something else.") }
    let(:error_with_404_string_status) { hlrp::Error.new("404", :something_completely_different, "Etc..") }
    let(:error_with_1000_string_status) { hlrp::Error.new("1000", :blue, "Blue.") }
    let(:error_with_false_status) { hlrp::Error.new(false, :yellow, "Yellow.") }
    let(:error_with_nil_status) { hlrp::Error.new(nil, :green, "Green.") }
    let(:error_with_string_that_cant_quite_convert_to_int) { hlrp::Error.new("123abc", :green, "Green.") }

    it "should still return a 422 status if given an empty array" do
      expect(hlrc.errors_to_render_args([])).to eq(json: { errors: [] }, status: 422)
    end

    it "should return a properly formatted hash of kwargs for render" do
      expect(error_with_403_integer_status.status).to eq(403)
      expect(error_with_404_integer_status.status).to eq(404)

      [
        [[error_with_403_integer_status], 403],
        [[error_with_403_integer_status, error_with_404_integer_status], 404],
        [[error_with_404_integer_status, error_with_403_integer_status], 404],
        [[error_with_404_integer_status, error_with_403_integer_status, error_with_1000_integer_status], 1000],
        [[error_with_1000_string_status, error_with_403_string_status, error_with_404_string_status], 1000],
        [[error_with_1000_integer_status, error_with_403_string_status, error_with_404_string_status], 1000],
        [[error_with_1000_string_status, error_with_403_integer_status, error_with_404_string_status], 1000],
        [
          [
            error_with_403_integer_status,
            error_with_404_integer_status,
            error_with_1000_integer_status,
            error_with_403_string_status,
            error_with_404_string_status,
            error_with_1000_string_status
          ], 1000
        ]
      ].each do |(array, status)|
        expect(hlrc.errors_to_render_args(array)).to eq(json: { errors: array }, status: status)
      end

      [
        [error_with_nil_status],
        [error_with_false_status],
        [error_with_404_integer_status, error_with_403_integer_status, error_with_nil_status]
      ].each do |array|
        expect { hlrc.errors_to_render_args(array) }.to raise_error(TypeError)
      end

      array = [error_with_string_that_cant_quite_convert_to_int]
      expect { hlrc.errors_to_render_args(array) }.to raise_error(ArgumentError)
    end
  end

  context "#error_from_objects_error_code" do
    let(:code_a) { :incident_flash }
    let(:object_a) do
      Intake.new(error_code: code_a)
    end

    let(:code_b) { :invalid_file_number }
    let(:object_b) do
      hlrp::StartError.new(Intake.new(error_code: code_b))
    end

    subject { hlrc.method(:error_from_objects_error_code) }
    it "should return the correct error" do
      [
        [[object_a, object_b], code_a],
        [[object_b, object_a], code_b],
        [[object_a], code_a],
        [[object_b], code_b],
        [[nil], nil]
      ].each do |objects, code|
        expect(hlrc.error_from_objects_error_code(*objects)).to eq(hlrp.error_from_error_code(code))
      end
    end
  end
end

describe hlrc, :all_dbs, type: :request do
  include IntakeHelpers

  before do
    Timecop.freeze(post_ama_start_date)

    [:establish_claim!, :create_contentions!, :associate_rating_request_issues!].each do |method|
      allow(Fakes::VBMSService).to receive(method).and_call_original
    end
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

    it "should return a 422 on failure" do
      post("/api/v3/decision_review/higher_level_reviews",
           params: {})
      expect(response).to have_http_status(:error)
    end
  end

  describe "#create" do
    let(:category) { "Words ending in urple" }
    it "should return a 422 on failure" do
      post("/api/v3/decision_review/higher_level_reviews",
           params: params)
      expect(response).to have_http_status(422)

      error = hlrp.error_from_error_code(:unknown_category_for_benefit_type)
      expect(JSON.parse(response.body)).to eq({ errors: [error] }.as_json)
    end
  end
end

# describe "#mock_create" do
#   it "should return a 202 on success" do
#     post "/api/v3/decision_review/higher_level_reviews"
#     expect(response).to have_http_status(202)
#   end
#   it "should be a jsonapi IntakeStatus response" do
#     post "/api/v3/decision_review/higher_level_reviews"
#     json = JSON.parse(response.body)
#     expect(json["data"].keys).to include("id", "type", "attributes")
#     expect(json["data"]["type"]).to eq "IntakeStatus"
#     expect(json["data"]["attributes"]["status"]).to be_a String
#   end
#   it "should include a Content-Location header" do
#     post "/api/v3/decision_review/higher_level_reviews"
#     expect(response.headers.keys).to include("Content-Location")
#     expect(response.headers["Content-Location"]).to match(
#       "/api/v3/decision_review/higher_level_reviews/intake_status"
#     )
#   end
# end
