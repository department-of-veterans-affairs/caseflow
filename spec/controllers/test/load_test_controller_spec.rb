# frozen_string_literal: true

describe Test::LoadTestsController, :postgres, type: :controller do
  let(:css_id) { "VACOUSER" }
  let(:email) { "user@example.com" }
  let!(:user) { create(:user, css_id: css_id, email: email) }

  before do
    User.authenticate!(user: user)
  end

  context "#index" do
    it "accesses load testing page" do
      get :index
      expect(response.status).to eq 200
    end
  end

  context "#target" do
    context "providing target_id" do
      let(:appeal_with_uuid) do
        Appeal.new(veteran_file_number: "1234",
                   uuid: "79166847-1e99-4921-a084-62963d0fc63e")
      end
      let(:legacy_appeal_with_vacols_id) { LegacyAppeal.new(vacols_id: "123") }

      it "gets Appeal target information" do
        appeal_with_uuid.save!
        get :target, params: { target_type: "Appeal" }
        expect(response.status).to eq 200
        expect(JSON.parse(response.body)["data"]).to eq(appeal_with_uuid.uuid)
      end

      it "gets LegacyAppeal target information" do
        legacy_appeal_with_vacols_id.save!
        get :target, params: { target_type: "LegacyAppeal" }
        expect(response.status).to eq 200
        expect(JSON.parse(response.body)["data"]).to eq(legacy_appeal_with_vacols_id.vacols_id)
      end
    end

    context "not providing target_id" do
      let(:appeal) { Appeal.new(veteran_file_number: "1234") }
      let(:supplemental_claim) { SupplementalClaim.new(veteran_file_number: "12345") }

      it "gets Appeal target information" do
        appeal.save!
        appeal.reload
        get :target, params: { target_type: "Appeal" }
        expect(response.status).to eq 200
        expect(JSON.parse(response.body)["data"]).to eq(appeal.uuid)
      end

      it "gets SupplementalClaim target information" do
        supplemental_claim.save!
        supplemental_claim.reload
        get :target, params: { target_type: "SupplementalClaim" }
        expect(response.status).to eq 200
        expect(JSON.parse(response.body)["data"]).to eq(supplemental_claim.uuid)
      end
    end
  end
end
