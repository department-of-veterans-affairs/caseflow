# frozen_string_literal: true

RSpec.describe CavcDashboardController, type: :controller do
  # add organization to this user once they are implemented
  let(:authorized_user) { create(:user) }
  let(:occteam_organization) { OccTeam.singleton }
  let(:oicteam_organization) { OaiTeam.singleton }
  before do
    User.authenticate!(user: authorized_user)
    occteam_organization.add_user(authorized_user)
    oicteam_organization.add_user(authorized_user)
  end

  context "for routes not specific to an appeal" do
    it "#cavc_decision_reasons returns all CavcDecisionReasons" do
      Seeds::CavcDashboardData.new.seed!

      get :cavc_decision_reasons

      expect(response.status).to eq 200
      expect(JSON.parse(response.body).count).to eq CavcDecisionReason.count
    end

    it "#cavc_selection_bases returns all CavcSelectionBases in DB" do
      Seeds::CavcSelectionBasisData.new.seed!

      get :cavc_selection_bases

      expect(response.status).to eq 200
      expect(JSON.parse(response.body).count).to eq CavcSelectionBasis.count
    end
  end

  context "for routes specific to an appeal" do
    it "#index returns nil for cavc_dashboards if appeal_id doesn't match any remands" do
      appeal = create(:appeal)

      get :index, params: { format: :json, appeal_id: appeal.uuid }
      response_body = JSON.parse(response.body)

      expect(response_body.key?("cavc_dashboards")).to be true
      expect(response_body["cavc_dashboards"]).to be nil
    end

    it "#index creates new dashboard and returns index data from format.json" do
      Seeds::CavcDashboardData.new.seed!

      remand = CavcRemand.last
      appeal_uuid = Appeal.find(remand.remand_appeal_id).uuid

      get :index, params: { format: :json, appeal_id: appeal_uuid }
      response_body = JSON.parse(response.body)
      dashboard = CavcDashboard.find_by(cavc_remand: remand)

      expect(response_body.key?("cavc_dashboards")).to be true
      expect(response_body["cavc_dashboards"][0]["cavc_dashboard_dispositions"].count)
        .to eq CavcDashboardDisposition.where(cavc_dashboard: dashboard).count
    end
  end
end
