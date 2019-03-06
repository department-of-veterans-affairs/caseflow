# frozen_string_literal: true

RSpec.describe AdvanceOnDocketMotionsController, type: :controller do
  describe "POST aod_team" do
    context "request to create as aod" do
      let(:aod) { AodTeam.singleton }
      let(:aod_user) { FactoryBot.create(:user) }
      let(:appeal) { FactoryBot.create(:appeal, veteran: FactoryBot.create(:veteran)) }

      before do
        OrganizationsUser.add_user_to_organization(aod_user, aod)
        User.authenticate!(user: aod_user)
      end

      it "should create" do
        post :create, params: { appeal_id: appeal.uuid, advance_on_docket_motions: {
          reason: "financial_distress", granted: "granted"
        } }
        expect(response.status).to eq 200
      end
    end
    context "request to create as non-aod" do
      let(:non_aod_user) { FactoryBot.create(:user) }
      let(:appeal) { FactoryBot.create(:appeal, veteran: FactoryBot.create(:veteran)) }

      before do
        User.authenticate!(user: non_aod_user)
      end

      it "should NOT create and return FORBIDDEN 403" do
        post :create, params: { appeal_id: appeal.uuid, advance_on_docket_motions: {
          reason: "financial_distress", granted: "granted"
        } }
        expect(response.status).to eq 403
      end
    end
  end
end
