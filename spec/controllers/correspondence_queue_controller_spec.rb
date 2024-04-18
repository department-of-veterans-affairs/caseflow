# frozen_string_literal: true

RSpec.describe CorrespondenceQueueController, :all_dbs, type: :controller do
  let(:current_user) { create(:user) }

  before do
    FeatureToggle.enable!(:correspondence_queue)
  end

  describe "GET #correspondence_cases" do
    before do
      MailTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
      get :correspondence_cases
    end

    it "returns a successful response" do
      expect(response).to have_http_status(:ok)
    end

    it "redirects mail supervisor" do
      InboundOpsTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
      get :correspondence_cases

      expect(response.status).to eq 302
      expect(response.body.include?("/queue/correspondence/team")).to eq true
    end

    it "responds to json format request" do
      request.accept = "application/json"
      get :correspondence_cases

      body = JSON.parse(response.body, symbolize_names: true)
      expect(body.keys.include?(:correspondence_config)).to eq true
    end
  end

  describe "GET #correspondence_team" do
    before do
      InboundOpsTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
      get :correspondence_team
    end

    it "returns a 200 response" do
      expect(response).to have_http_status(:ok)
    end

    it "responds to json format request" do
      request.accept = "application/json"
      get :correspondence_team

      body = JSON.parse(response.body, symbolize_names: true)
      expect(body.key?(:correspondence_config)).to eq true
    end
  end
end
