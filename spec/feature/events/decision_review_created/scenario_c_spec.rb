# frozen_string_literal: true

RSpec.describe Api::Events::V1::DecisionReviewCreatedController, type: :controller do
  describe "POST #decision_review_created" do
    let!(:current_user) { User.authenticate! }
    let(:api_key) { ApiKey.create!(consumer_name: "API TEST TOKEN") }

    def json_payload
      {
        "css_id": "BVADWISE",
        "detail_type": "HigherLevelReview",
        "station": "101",
        "intake": {
          "started_at": 1702067143435,
          "completion_started_at": 1702067145000,
          "completed_at": 1702067145000,
          "completion_status": "success",
          "type": "HigherLevelReviewIntake",
          "detail_type": "HigherLevelReview"
        },
        "veteran": {
          "participant_id": "1826209",
          "bgs_last_synced_at": 1708533584000,
          "name_suffix": nil,
          "date_of_death": nil
        },
        "claimant": {
          "payee_code": "00",
          "type": "VeteranClaimant",
          "participant_id": "1826209",
          "name_suffix": nil
        },
        "claim_review": {
          "benefit_type": "compensation",
          "filed_by_va_gov": false,
          "legacy_opt_in_approved": false,
          "receipt_date": 20231208,
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
          "claim_date": 20231208,
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
        "request_issues": [
          {
            "benefit_type": "compensation",
            "contested_issue_description": nil,
            "contention_reference_id": 7905752,
            "contested_rating_decision_reference_id": nil,
            "contested_rating_issue_profile_date": nil,
            "contested_rating_issue_reference_id": nil,
            "contested_decision_issue_id": nil,
            "decision_date": 20231220,
            "ineligible_due_to_id": nil,
            "ineligible_reason": nil,
            "is_unidentified": false,
            "unidentified_issue_text": nil,
            "nonrating_issue_category": "Accrued Benefits",
            "nonrating_issue_description": "The user entered description if the issue is a nonrating issue",
            "untimely_exemption": nil,
            "untimely_exemption_notes": nil,
            "vacols_id": nil,
            "vacols_sequence_id": nil,
            "closed_at": nil,
            "closed_status": nil,
            "contested_rating_issue_diagnostic_code": nil,
            "ramp_claim_id": nil,
            "rating_issue_associated_at": nil,
            "nonrating_issue_bgs_id": "13"
          }
        ]
      }
    end

    let!(:valid_params) do
      {
        event_id: "123",
        claim_id: "9999",
        payload: JSON.generate(json_payload)
      }
    end

    context "with a valid token and user exists" do
      it "returns success response when veteran exists, is claimant, is HLR,
       Person does not exist and request issues exist" do
        vet = Veteran.create!(
          file_number: "77799777",
          ssn: "123456789",
          first_name: "John",
          last_name: "Smith",
          middle_name: "Alexander",
          participant_id: "1826209",
          bgs_last_synced_at: 1708533584000,
          name_suffix: nil,
          date_of_death: nil
        )
        request.headers["Authorization"] = "Token #{api_key.key_string}"
        request.headers["X-VA-Vet-SSN"] = "123456789"
        request.headers["X-VA-File-Number"] = "77799777"
        request.headers["X-VA-Vet-First-Name"] = "John"
        request.headers["X-VA-Vet-Last-Name"] = "Smith"
        request.headers["X-VA-Vet-Middle-Name"] = "Alexander"
        request.headers["date_of_birth"] = DateTime.now - 30.years
        request.headers["email_address"] = "jim@google.com"
        request.headers["first_name"] = "Jimmy"
        request.headers["last_name"] = "Longstocks"
        request.headers["middle_name"] = "Goob"
        request.headers["ssn"] = "989773212"
        expect(Person.find_by(participant_id: "1826209")).to eq(nil)
        post :decision_review_created, params: valid_params
        expect(response).to have_http_status(:created)
        expect(Veteran.find_by(file_number: "77799777")).to eq(vet)
        expect(Claimant.find_by(participant_id: "1826209")).to be_present
        expect(Person.find_by(participant_id: "1826209")).to be_present
        expect(HigherLevelReview.find_by(veteran_file_number: vet.file_number)).to be_present
        expect(RequestIssue.find_by(contention_reference_id: 7905752)).to be_present
      end
    end
  end
end
