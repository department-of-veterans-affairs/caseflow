# frozen_string_literal: true

RSpec.describe CavcDashboardController, type: :controller do
  # add organization to this user once they are implemented
  let(:authorized_user) { create(:user) }
  before { User.authenticate!(user: authorized_user) }

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
    before { Seeds::CavcDashboardData.new.seed! }

    it "#index returns index data from format.json" do
      remand = CavcRemand.last
      appeal_uuid = Appeal.find(remand.remand_appeal_id).uuid

      get :index, params: { format: :json, appeal_id: appeal_uuid }
      response_body = JSON.parse(response.body)

      expect(response_body.key?("dashboard_dispositions")).to be true
      expect(response_body["dashboard_dispositions"].count)
        .to eq CavcDashboardDisposition.where(cavc_remand: remand).count
    end
  end
end
