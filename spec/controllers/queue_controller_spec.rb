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

  describe "redirect_short_uuids before_action" do
    context "with first 8 characters of a uuid" do
      let(:appeal) { create(:appeal) }
      let(:user) { create(:user) }

      before { User.authenticate!(user: user) }
      after { User.unauthenticate! }

      it "loads the page as normal" do
        get(:index, params: { external_id: appeal.uuid[0..7] })
        expect(response.status).to eq 302
        expect(response.headers["Location"]).to eq "http://test.host/queue/appeals/#{appeal.uuid}"
      end
    end
  end
end
