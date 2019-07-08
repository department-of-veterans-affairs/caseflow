# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::V2::HearingsController, type: :controller, focus: true do
  let(:api_key) { ApiKey.create!(consumer_name: "Jobs Tester").key_string }

  before(:each) do
    request.headers["Authorization"] = "Token token=#{api_key}"
  end

  describe "GET hearings by hearing day" do
    context "with valid API key" do
      it "returns 422 with invalid date" do
        get :show, params: { hearing_day: "invalid" }
        expect(response.status).to eq 422
      end

      it "returns 404 when no hearings days are found" do
        get :show, params: { hearing_day: "2019-07-07" }
        expect(response.status).to eq 404
      end
    end

    context "with API that does not exists" do
      let(:api_key) { "does-not-exist" }

      it "returns a 401 error with invalid date" do
        get :show, params: { hearing_day: "invalid" }
        expect(response.status).to eq 401
      end

      it "returns a 401 error with a valid date" do
        get :show, params: { hearing_day: "2019-07-07" }
        expect(response.status).to eq 401
      end
    end
  end
end
