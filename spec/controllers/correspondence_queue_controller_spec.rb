# frozen_string_literal: true

RSpec.describe CorrespondenceQueueController, :all_dbs, type: :controller do
  let(:current_user) { create(:user) }
  let(:veteran) { create(:veteran) }
  let(:correspondence) { create(:correspondence, veteran: veteran) }

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
  end

  describe "GET #correspondence_team" do
    before do
      InboundOpsTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
    end

    it "returns cancel intake response" do
      get :correspondence_team, params: { userAction: "cancel_intake",
                                          user: current_user.css_id,
                                          correspondence_uuid: correspondence.uuid }
      expect(controller.view_assigns["response_header"]).to eq("You have successfully cancelled the intake form")
      expect(controller.view_assigns["response_message"]).to eq("#{veteran.name}'s correspondence (ID: #{correspondence.id}) has been returned to the supervisor's queue for assignment.")
    end

    it "returns intake continue later response" do
      get :correspondence_team, params: { userAction: "continue_later",
                                          user: current_user.css_id,
                                          correspondence_uuid: correspondence.uuid }
      expect(controller.view_assigns["response_header"]).to eq("You have successfully saved the intake form")
      expect(controller.view_assigns["response_message"]).to eq("You can continue from step three of the intake form for #{veteran.name}'s correspondence (ID: #{correspondence.id}) at a later date.")
    end
  end
end
