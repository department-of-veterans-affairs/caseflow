# frozen_string_literal: true

# rubocop:disable Style/NumericLiterals

RSpec.describe Api::Events::V1::DecisionReviewCreatedController, type: :controller do
  describe "POST #decision_review_created" do
    let!(:current_user) { User.authenticate! }
    let(:api_key) { ApiKey.create!(consumer_name: "API TEST TOKEN") }
    let!(:person) do
      Person.create(participant_id: "1826209", first_name: "Jimmy", last_name: "Longstocks",
                    middle_name: "Goob", ssn: "989773212", name_suffix: "")
    end

    def json_payload
      {
        "event_id": "123",
        "claim_id": "9999",
        "css_id": "BVADWISE",
        "detail_type": "SupplementalClaim",
        "station": "101",
        "intake": {
          "started_at": 1702067143435,
          "completion_started_at": 1702067145000,
          "completed_at": 1702067145000,
          "completion_status": "success",
          "type": "SupplementalClaimIntake",
          "detail_type": "SupplementalClaim"
        },
        "veteran": {
          "participant_id": "1826209",
          "bgs_last_synced_at": 1708533584000,
          "name_suffix": nil,
          "date_of_death": nil
        },
        "claimant": {
          "payee_code": "00",
          "type": "Claimant",
          "participant_id": "1826209",
          "name_suffix": nil
        },
        "claim_review": {
          "benefit_type": "compensation",
          "filed_by_va_gov": false,
          "legacy_opt_in_approved": false,
          "receipt_date": 19699,
          "veteran_is_not_claimant": true,
          "establishment_attempted_at": 1702067145000,
          "establishment_last_submitted_at": 1702067145000,
          "establishment_processed_at": 1702067145000,
          "establishment_submitted_at": 1702067145000,
          "informal_conference": false,
          "same_office": false
        },
        "end_product_establishment": {
          "benefit_type_code": "1",
          "claim_date": 19699,
          "code": "030HLRNR",
          "modifier": "030",
          "payee_code": "00",
          "reference_id": "337534",
          "limited_poa_access": nil,
          "limited_poa_code": nil,
          "committed_at": 1702067145000,
          "established_at": 1702067145000,
          "last_synced_at": 1702067145000,
          "synced_status": "RW",
          "development_item_reference_id": nil
        },
        "request_issues": []
      }
    end

    let!(:valid_params) do
      json_payload
    end

    context "with a valid token and user exists" do
      it "returns success response when user does not exist, veteran does not exists, is claimant,
          is Supplemental claim, person exists and request issues don't exist" do
        request.headers["Authorization"] = "Token #{api_key.key_string}"
        request.headers["X-VA-Vet-SSN"] = "123456789"
        request.headers["X-VA-File-Number"] = "77799777"
        request.headers["X-VA-Vet-First-Name"] = "John"
        request.headers["X-VA-Vet-Last-Name"] = "Smith"
        request.headers["X-VA-Vet-Middle-Name"] = "Alexander"
        request.headers["X-VA-Claimant-DOB"] = DateTime.now - 30.years
        request.headers["X-VA-Claimant-Email"] = "jim@google.com"
        request.headers["X-VA-Claimant-First-Name"] = "Jimmy"
        request.headers["X-VA-Claimant-Last-Name"] = "Longstocks"
        request.headers["X-VA-Claimant-Middle-Name"] = "Goob"
        request.headers["X-VA-Claimant-SSN"] = "989773212"
        expect(Person.find_by(participant_id: "1826209")).to be_present
        expect(Person.count).to eq(1)
        expect(User.find_by(css_id: "BVADWISE")).to eq(nil)
        expect(Veteran.find_by(file_number: "77799777")).to eq(nil)
        post :decision_review_created, params: valid_params
        expect(response).to have_http_status(:created)
        expect(User.find_by(css_id: "BVADWISE")).to be_present
        expect(Veteran.find_by(file_number: "77799777")).to be_present
        expect(Claimant.find_by(participant_id: "1826209")).to be_present
        expect(SupplementalClaim.find_by(veteran_file_number: "77799777")).to be_present
        expect(RequestIssue.find_by(contention_reference_id: 7905752)).to be_nil
        expect(Person.count).to eq(1)
      end
    end
  end
end

# rubocop:enable Style/NumericLiterals
