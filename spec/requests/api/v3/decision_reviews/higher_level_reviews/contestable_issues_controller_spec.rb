# frozen_string_literal: true

describe Api::V3::DecisionReviews::HigherLevelReviews::ContestableIssuesController, :postgres, type: :request do
  let(:decision_review_type) { :higher_level_review }
  let(:source) { create(:higher_level_review, veteran_file_number: veteran.file_number, same_office: false) }
  let(:benefit_type) { "compensation" }

  include IntakeHelpers

  before do
    FeatureToggle.enable!(:api_v3_higher_level_reviews_contestable_issues)

    Timecop.freeze(post_ama_start_date)
  end

  after { FeatureToggle.disable!(:api_v3_higher_level_reviews_contestable_issues) }

  include_examples "contestable issues index requests"

  describe "#index" do
    include_context "contestable issues request context", include_shared: true
    include_context "contestable issues request index context", include_shared: true

    context do
      let(:benefit_type) { "Greetings!" }
      it "should return a 422 when the benefit type is unknown" do
        get_issues
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context do
      let(:benefit_type) { nil }
      it "should return a 422 when the benefit type is missing" do
        get_issues
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context do
      let(:benefit_type) { "" }
      it "should return a 422 when the benefit type is blank" do
        get_issues
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "when feature toggle is not enabled" do
      before { FeatureToggle.disable!(:api_v3_higher_level_reviews_contestable_issues) }

      it "should return a 501 response" do
        get_issues
        expect(response).to have_http_status(:not_implemented)
      end

      it "should have a jsonapi error response" do
        get_issues
        expect { JSON.parse(response.body) }.to_not raise_error
        parsed_response = JSON.parse(response.body)
        expect(parsed_response["errors"]).to be_a Array
        expect(parsed_response["errors"].first).to include("status", "title", "detail")
      end
    end
  end
end
