# frozen_string_literal: true

RSpec.describe CorrespondenceDetailsController, :all_dbs, type: :controller do
  let(:current_user) { create(:user) }
  let(:veteran) { create(:veteran) }
  let(:correspondence) { create(:correspondence, veteran: veteran) }

  before do
    Fakes::Initializer.load!
    FeatureToggle.enable!(:correspondence_queue)
    User.authenticate!(roles: ["Mail Intake"])
    correspondence.update(veteran: veteran)
    InboundOpsTeam.singleton.add_user(current_user)
    User.authenticate!(user: current_user)
    correspondence.update(veteran: veteran)
  end

  describe "GET #correspondence_details" do
    before do
      InboundOpsTeam.singleton.add_user(current_user)
      User.authenticate!(user: current_user)
      get :correspondence_details, params: { correspondence_uuid: correspondence.uuid }, format: :json
    end

    it "returns a successful response" do
      expect(response).to have_http_status(:ok)
    end
  end
end
