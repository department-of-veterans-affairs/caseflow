# frozen_string_literal: true

require "rails_helper"

RSpec.describe Hearings::WorksheetsController, type: :controller do
  let!(:user) { User.authenticate!(roles: ["Hearing Prep"]) }
  let(:legacy_hearing) { create(:legacy_hearing) }
  let(:hearing) { create(:hearing, :with_tasks) }

  describe "SHOW worksheet" do
    it "returns legacy data with success" do
      get :show, params: { id: legacy_hearing.external_id }, format: "json"
      response_hearing = JSON.parse(response.body)
      expect(response.status).to eq 200
      expect(response_hearing[:veteran_gender]).to eq nil
      expect(response_hearing[:veteran_age]).to eq nil
      expect(response_hearing["id"]).to eq legacy_hearing.id
      expect(response_hearing["external_id"]).to eq legacy_hearing.external_id
    end

    it "returns data with success" do
      get :show, params: { id: hearing.external_id }, format: "json"
      response_hearing = JSON.parse(response.body)
      expect(response.status).to eq 200
      expect(response_hearing["external_id"]).to eq hearing.external_id
    end

    it "should fail with 404 error message" do
      get :show, params: { id: "12121" }, format: "json"
      expect(response.status).to eq 404
      body = response.body
      expect(body).to eq "{\"errors\":[{\"message\":\"Couldn't find LegacyHearing\",\"code\":1000}]}"
    end
  end
end
