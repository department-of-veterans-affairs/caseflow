# frozen_string_literal: true

require "support/intake_helpers"
require "support/vacols_database_cleaner"

describe Api::V3::DecisionReview::HigherLevelReviewsController, :all_dbs, type: :request do
  include IntakeHelpers

  before do
    FeatureToggle.enable!(:api_v3)

    Timecop.freeze(post_ama_start_date)

    [:establish_claim!, :create_contentions!, :associate_rating_request_issues!].each do |method|
      allow(Fakes::VBMSService).to receive(method).and_call_original
    end
  end

  after do
    FeatureToggle.disable!(:api_v3)
  end

  let!(:api_key) { ApiKey.create!(consumer_name: "ApiV3 Test Consumer").key_string }

  let(:veteran_file_number) { "64205050" }

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
  let!(:rating) { generate_rating(veteran, promulgation_date, profile_date) }
  let(:receipt_date) { Time.zone.today - 5.days }
  let(:informal_conference) { true }
  let(:same_office) { false }
  let(:legacy_opt_in_approved) { true }
  let(:benefit_type) { "compensation" }
  let(:category) { "Apportionment" }
  let(:decision_date) { Time.zone.today - 10.days }
  let(:decision_text) { "Some text here." }
  let(:notes) { "not sure if this is on file" }
  let(:attributes) do
    {
      receiptDate: receipt_date.strftime("%F"),
      informalConference: informal_conference,
      sameOffice: same_office,
      legacyOptInApproved: legacy_opt_in_approved,
      benefitType: benefit_type
    }
  end
  let(:veteran_obj) do
    {
      data: {
        type: "Veteran",
        id: veteran_file_number
      }
    }
  end
  let(:claimant_obj) do
    {
      data: {
        type: "Claimant",
        id: 44,
        meta: {
          payeeCode: { a: 1 }
        }
      }
    }
  end
  let(:relationships) do
    {
      veteran: veteran_obj,
      claimant: claimant_obj
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
          decisionIssueId: 12,
          decisionDate: decision_date.strftime("%F"),
          decisionText: decision_text,
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

  def post_params
    post(
      "/api/v3/decision_review/higher_level_reviews",
      params: params,
      headers: { "Authorization" => "Token #{api_key}" }
    )
  end

  describe "#create" do
    describe "general cases" do
      it "should return a 202 on success" do
        allow(User).to receive(:api_user) { build(:user) }
        post_params
        expect(response).to have_http_status(202)
      end

      describe do
        let(:params) { {} }
        it "should return an error status on failure" do
          post_params
          error = Api::V3::DecisionReview::IntakeError.new(:malformed_request)

          expect(response).to have_http_status(error.status)
          expect(JSON.parse(response.body)).to eq(
            Api::V3::DecisionReview::IntakeErrors.new([error]).render_hash[:json].as_json
          )
        end
      end
    end

    describe "test error case: unknown_category_for_benefit_type" do
      let(:category) { "Words ending in urple" }
      it "should return a 422 on this failure" do
        post_params
        error = Api::V3::DecisionReview::IntakeError.new(:request_issue_category_invalid_for_benefit_type)

        expect(response).to have_http_status(error.status)
        expect(JSON.parse(response.body)).to eq(
          Api::V3::DecisionReview::IntakeErrors.new([error]).render_hash[:json].as_json
        )
      end
    end

    describe "error cases" do
      describe "unknown_error" do
        let(:attributes) do
          {
            receiptDate: "wrench",
            informalConference: informal_conference,
            sameOffice: same_office,
            legacyOptInApproved: legacy_opt_in_approved,
            benefitType: benefit_type
          }
        end
        it "should return 500/unknown_error" do
          post_params
          error = Api::V3::DecisionReview::IntakeError.new

          expect(response).to have_http_status(error.status)
          expect(JSON.parse(response.body)).to eq(
            Api::V3::DecisionReview::IntakeErrors.new([error]).render_hash[:json].as_json
          )
        end
      end

      describe "reserved_veteran_file_number" do
        let(:veteran_file_number) { "123456789" }
        it "should return 500/reserved_veteran_file_number" do
          allow(Rails).to receive(:deploy_env?).and_return(true)
          post_params
          error = Api::V3::DecisionReview::IntakeError.new(:reserved_veteran_file_number)

          expect(response).to have_http_status(error.status)
          expect(JSON.parse(response.body)).to eq(
            Api::V3::DecisionReview::IntakeErrors.new([error]).render_hash[:json].as_json
          )
        end
      end
    end
  end
end
