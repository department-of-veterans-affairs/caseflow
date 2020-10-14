# frozen_string_literal: true

describe Api::V3::DecisionReviews::HigherLevelReviews::ContestableIssuesController, :postgres, type: :request do
  let(:decision_review_type) { :higher_level_review }
  let(:source) { create(:higher_level_review, veteran_file_number: veteran.file_number, same_office: false) }
  let(:benefit_type) { "compensation" }

  include_examples "contestable issues index requests"

  describe "#index" do
    before { FeatureToggle.enable!(:api_v3) }
    after do
      User.instance_variable_set(:@api_user, nil)
      FeatureToggle.disable!(:api_v3)
    end

    let!(:api_key) { ApiKey.create!(consumer_name: "ApiV3 Test Consumer").key_string }
    let(:veteran) { create(:veteran).unload_bgs_record }
    let(:ssn) { veteran.ssn }
    let(:response_data) { JSON.parse(response.body)["data"] }
    let(:receipt_date) { Time.zone.today }

    let(:get_issues) do
      benefit_type_url_string = benefit_type ? "/#{benefit_type}" : ""
      get(
        "/api/v3/decision_reviews/#{decision_review_type}s/contestable_issues#{benefit_type_url_string}",
        headers: {
          "Authorization" => "Token #{api_key}",
          "X-VA-SSN" => ssn,
          "X-VA-Receipt-Date" => receipt_date.try(:strftime, "%F") || receipt_date
        }
      )
    end

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
  end
end
