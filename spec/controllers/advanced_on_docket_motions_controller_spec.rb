# frozen_string_literal: true

RSpec.describe AdvanceOnDocketMotionsController, :postgres, type: :controller do
  describe "POST aod_team" do
    context "request to create as aod" do
      let(:aod) { AodTeam.singleton }
      let(:aod_user) { create(:user) }
      let(:appeal) { create(:appeal, veteran: create(:veteran)) }

      before do
        aod.add_user(aod_user)
        User.authenticate!(user: aod_user)
      end

      subject do
        post :create, params: { appeal_id: appeal.uuid, advance_on_docket_motions: {
          reason: "financial_distress", granted: "granted"
        } }
      end

      it "should create" do
        subject
        expect(response.status).to eq 200
      end

      context "where case has an existing aod motion" do
        let!(:aod_motion) do
          AdvanceOnDocketMotion.create(
            person: appeal.claimant.person,
            granted: false,
            user: aod_user,
            reason: "serious_illness"
          )
        end

        it "overrwrites existing motion" do
          subject
          motions = appeal.claimant.person.advance_on_docket_motions
          expect(motions.count).to eq 1
          expect(motions.first.granted).to be(true)
          expect(motions.first.reason).to eq("financial_distress")
        end
      end
    end
    context "request to create as non-aod" do
      let(:non_aod_user) { create(:user) }
      let(:appeal) { create(:appeal, veteran: create(:veteran)) }

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
