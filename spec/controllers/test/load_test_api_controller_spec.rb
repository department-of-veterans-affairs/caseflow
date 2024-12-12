# frozen_string_literal: true

require "webmock/rspec"

describe Test::LoadTestApiController, :postgres, type: :controller do
  let!(:api_key) { ApiKey.create(consumer_name: "Load Testing", key_string: "test") }
  let(:body) do
    {
      "user": {
        "station_id": "307",
        "regional_office": "RO91",
        "roles": ["Build HearSched", "Edit HearSched", "Mail Intake"],
        "functions": {
          "System Admin": true
        },
        "organizations": [
          { "url": "BVA Intake", "admin": true }
        ],
        "feature_toggles": {
          "listed_granted_substitution_before_dismissal": true,
          "mdr_cavc_remand": true
        }
      }
    }
  end

  context "Outside of prodtest env" do
    before do
      request.headers["Authorization"] = "Bearer test"
    end

    it "returns 404" do
      post :user, params: body
      expect(response).to redirect_to("http://test.host/404")
      expect(response.status).to eq 302
    end
  end

  context "Only within the prodtest env" do
    before do
      allow(Rails).to receive(:deploy_env?).and_return(:prodtest)
      request.headers["Authorization"] = "Bearer test"
    end

    context "with no api key" do
      before do
        request.headers["Authorization"] = nil
      end
      it "returns 401" do
        post :user, params: body
        expect(response.status).to eq 401
      end
    end

    context "#user" do
      before do
        Organization.create(name: "BVA Intake", url: "bva-intake", type: "BvaIntake")
      end
      it "modifies the load test user" do
        post :user, params: body
        expect(response.status).to eq 200
        expect(User.find_by_css_id("LOAD_TESTER").organizations.length).to eq 1
      end

      it "returns an IDT Token in the response" do
        post :user, params: body
        expect(response.status).to eq 200
        expect(JSON.parse(response.body)["idt_token"]).not_to be(nil)
      end
    end

    context "#target" do
      context "providing target_id" do
        let(:appeal_with_uuid) do
          Appeal.new(
            veteran_file_number: "1234",
            uuid: "79166847-1e99-4921-a084-62963d0fc63e"
          )
        end
        let(:legacy_appeal_with_vacols_id) { LegacyAppeal.new(vacols_id: "123") }

        it "gets Appeal target information" do
          appeal_with_uuid.save!
          get :target, params: { target_type: "Appeal", target_id: "79166847-1e99-4921-a084-62963d0fc63e" }
          expect(response.status).to eq 200
          expect(JSON.parse(response.body)["data"]).to eq(appeal_with_uuid.as_json)
          get :target, params: { target_type: "Appeal", target_id: "79166847-1e99-4921-a084-incorrectid" }
          expect(response.status).to eq 404
        end

        it "gets LegacyAppeal target information" do
          legacy_appeal_with_vacols_id.save!
          get :target, params: { target_type: "LegacyAppeal", target_id: "123" }
          expect(response.status).to eq 200
          expect(JSON.parse(response.body)["data"]).to eq(legacy_appeal_with_vacols_id.as_json)
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
          expect(JSON.parse(response.body)["data"]).to eq(appeal.as_json)
        end

        it "gets SupplementalClaim target information" do
          supplemental_claim.save!
          supplemental_claim.reload
          get :target, params: { target_type: "SupplementalClaim" }
          expect(response.status).to eq 200
          expect(JSON.parse(response.body)["data"]).to eq(supplemental_claim.as_json)
        end
      end
    end
  end
end
