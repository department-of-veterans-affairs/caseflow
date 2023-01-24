# frozen_string_literal: true

RSpec.describe CavcDashboardController, type: :controller do
  # add organization to this user once they are implemented
  let(:authorized_user) { create(:user) }
  before { User.authenticate!(user: authorized_user) }

  it "#cavc_decision_reasons returns all CavcDecisionReasons in DB" do
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
