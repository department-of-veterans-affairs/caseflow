# frozen_string_literal: true

require "rails_helper"

RSpec.describe CorrespondenceDetailsController, :all_dbs, type: :controller do
  describe "GET #correspondence_details" do
    let!(:current_user) { create(:inbound_ops_team_supervisor) }
    let(:veteran) { create(:veteran) }
    let!(:correspondence) { create(:correspondence, :with_correspondence_intake_task, assigned_to: current_user) }

    before :each do
      Fakes::Initializer.load!
      User.authenticate!(user: current_user)
      FeatureToggle.enable!(:correspondence_queue)
      InboundOpsTeam.singleton.add_user(current_user)
      correspondence.update(veteran: veteran)
      correspondence.tasks.update(status: :completed)
    end

    context "when format is HTML" do
      it "responds successfully with an HTTP 200 status code" do
        get :correspondence_details, params: { correspondence_uuid: correspondence.uuid }, format: :html
        expect(response).to be_successful
        expect(response).to have_http_status(:ok)
      end
    end

    context "when format is JSON" do
      it "renders the correspondence details as JSON" do
        get :correspondence_details, params: { correspondence_uuid: correspondence.uuid }, format: :json
        json = JSON.parse(response.body)
        expect(response).to be_successful
        expect(response).to have_http_status(:ok)
        expect(json["correspondence"]).to be_present
      end
    end
  end
end
