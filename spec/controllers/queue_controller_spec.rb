# frozen_string_literal: true

RSpec.describe QueueController, :all_dbs, type: :controller do
  describe "GET /queue" do
    context "when user has access to queue" do
      let(:attorney_user) { create(:user) }
      let!(:vacols_atty) { create(:staff, :attorney_role, sdomainid: attorney_user.css_id) }

      before { User.authenticate!(user: attorney_user) }
      after { User.unauthenticate! }

      it "should return the queue landing page" do
        get :index
        expect(response.status).to eq 200
      end
      it "should call the verify_access method" do
        expect_any_instance_of(QueueController).to receive(:verify_access).exactly(1).times
        get :index
      end
    end
  end
end
