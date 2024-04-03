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
  end
end
