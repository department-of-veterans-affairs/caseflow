# frozen_string_literal: true

RSpec.describe CorrespondenceQueueController, :all_dbs, type: :controller do
  include CorrespondenceHelpers
  let(:current_user) { create(:user) }
  let(:veteran) { create(:veteran) }
  let(:correspondence) { create(:correspondence, veteran: veteran) }

  before do
    FeatureToggle.enable!(:correspondence_queue)
  end

  describe "GET #correspondence_cases" do
    before do
      InboundOpsTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
      get :correspondence_cases
    end

    it "returns a successful response" do
      expect(response).to have_http_status(:ok)
    end

    it "redirects mail supervisor" do
      InboundOpsTeam.singleton.add_user(current_user)
      MailTeam.singleton.add_user(current_user)
      OrganizationsUser.find_or_create_by!(
        organization: InboundOpsTeam.singleton,
        user: current_user
      ).update!(admin: true)
      User.authenticate!(user: current_user)

      get :correspondence_cases

      expect(response.status).to eq 302
      expect(response.body.include?("/queue/correspondence/team")).to eq true
    end

    it "responds to json format request" do
      request.accept = "application/json"
      get :correspondence_cases

      body = JSON.parse(response.body, symbolize_names: true)
      expect(body.key?(:correspondence_config)).to eq true
    end
  end

  describe "GET #correspondence_team" do
    before do
      InboundOpsTeam.singleton.add_user(current_user)
      MailTeam.singleton.add_user(current_user)
      OrganizationsUser.find_or_create_by!(
        organization: InboundOpsTeam.singleton,
        user: current_user
      ).update!(admin: true)
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

  describe "GET #correspondence_team" do
    before do
      inbound_ops_team_admin_setup
    end

    it "returns cancel intake response" do
      get :correspondence_team, params: { userAction: "cancel_intake",
                                          user: current_user.css_id,
                                          correspondence_uuid: correspondence.uuid }
      expect(controller.view_assigns["response_header"]).to eq("You have successfully cancelled the intake form")
      expect(controller.view_assigns["response_message"]).to eq("#{veteran.name}'s "\
        "correspondence has been returned to the supervisor's queue for assignment.")
    end

    it "returns intake continue later response" do
      get :correspondence_team, params: { userAction: "continue_later",
                                          user: current_user.css_id,
                                          correspondence_uuid: correspondence.uuid }
      expect(controller.view_assigns["response_header"]).to eq("You have successfully saved the intake form")
      expect(controller.view_assigns["response_message"]).to eq("You can continue from step three of the "\
        "intake form for #{veteran.name}'s correspondence at a later date.")
    end
  end
end
