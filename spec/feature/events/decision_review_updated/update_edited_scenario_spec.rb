# # frozen_string_literal: true

# # rubocop:disable Style/NumericLiterals

# RSpec.describe Api::Events::V1::DecisionReviewCreatedController, type: :controller do
#   # describe "POST #decision_review_created" do
#   #   let!(:current_user) { User.authenticate! }
#   #   let(:api_key) { ApiKey.create!(consumer_name: "API TEST TOKEN") }
#   #   let!(:person) do
#   #     Person.create(participant_id: "1826209", first_name: "Jimmy", last_name: "Longstocks",
#   #                   middle_name: "Goob", ssn: "989773212", name_suffix: "")
#   #   end

#   #   def json_test_payload
#   #     {
#   #       "event_id": "123",
#   #       "claim_id": "9999",
#   #       "css_id": "BVADWISE",
#   #       "detail_type": "HigherLevelReview",
#   #       "station": "101",
#   #       "intake": {
#   #         "started_at": 1702067143435,
#   #         "completion_started_at": 1702067145000,
#   #         "completed_at": 1702067145000,
#   #         "completion_status": "success",
#   #         "type": "HigherLevelReviewIntake",
#   #         "detail_type": "HigherLevelReview"
#   #       },
#   #       "veteran": {
#   #         "participant_id": "1826209",
#   #         "bgs_last_synced_at": 1708533584000,
#   #         "name_suffix": nil,
#   #         "date_of_death": nil
#   #       },
#   #       "claimant": {
#   #         "payee_code": "00",
#   #         "type": "VeteranClaimant",
#   #         "participant_id": "1826209",
#   #         "name_suffix": nil
#   #       },
#   #       "claim_review": {
#   #         "benefit_type": "compensation",
#   #         "filed_by_va_gov": false,
#   #         "legacy_opt_in_approved": false,
#   #         "receipt_date": 20231208,
#   #         "veteran_is_not_claimant": true,
#   #         "establishment_attempted_at": 1702067145000,
#   #         "establishment_last_submitted_at": 1702067145000,
#   #         "establishment_processed_at": 1702067145000,
#   #         "establishment_submitted_at": 1702067145000,
#   #         "informal_conference": false,
#   #         "same_office": false
#   #       },
#   #       "end_product_establishment": {
#   #         "benefit_type_code": "1",
#   #         "claim_date": 20231208,
#   #         "code": "030HLRNR",
#   #         "modifier": "030",
#   #         "payee_code": "00",
#   #         "reference_id": "337534",
#   #         "limited_poa_access": nil,
#   #         "limited_poa_code": nil,
#   #         "committed_at": 1702067145000,
#   #         "created_at": 1702067145000,
#   #         "last_synced_at": 1702067145000,
#   #         "synced_status": "RW",
#   #         "development_item_reference_id": nil
#   #       },
#   #       "request_issues": [
#   #         {
#   #           "decision_review_issue_id": 1,
#   #           "benefit_type": "compensation",
#   #           "contested_issue_description": nil,
#   #           "contention_reference_id": 7905752,
#   #           "contested_rating_decision_reference_id": nil,
#   #           "contested_rating_issue_profile_date": nil,
#   #           "contested_rating_issue_reference_id": nil,
#   #           "contested_decision_issue_id": nil,
#   #           "decision_date": 20231220,
#   #           "ineligible_due_to_id": nil,
#   #           "ineligible_reason": nil,
#   #           "is_unidentified": false,
#   #           "unidentified_issue_text": nil,
#   #           "nonrating_issue_category": "Accrued Benefits",
#   #           "nonrating_issue_description": "The user entered description if the issue is a nonrating issue",
#   #           "untimely_exemption": nil,
#   #           "untimely_exemption_notes": nil,
#   #           "vacols_id": nil,
#   #           "vacols_sequence_id": nil,
#   #           "closed_at": nil,
#   #           "closed_status": nil,
#   #           "contested_rating_issue_diagnostic_code": nil,
#   #           "ramp_claim_id": nil,
#   #           "rating_issue_associated_at": nil,
#   #           "nonrating_issue_bgs_id": "13",
#   #           "nonrating_issue_bgs_source": "Test Source"
#   #         }
#   #       ]
#   #     }
#   #   end

#   #   let!(:valid_params) do
#   #     json_test_payload
#   #   end

#   #   context "with a valid token and user exists" do
#   #     it "returns success response when user exists, veteran exists, is claimant,
#   #     is HLR, person exists and request issues exist" do
#   #       vet = Veteran.create!(
#   #         file_number: "77799777",
#   #         ssn: "123456789",
#   #         first_name: "John",
#   #         last_name: "Smith",
#   #         middle_name: "Alexander",
#   #         participant_id: "1826209",
#   #         bgs_last_synced_at: 1708533584000,
#   #         name_suffix: nil,
#   #         date_of_death: nil
#   #       )
#   #       user = User.create(css_id: "BVADWISE", station_id: 101, status: Constants.USER_STATUSES.inactive)
#   #       expect(Person.find_by(participant_id: "1826209")).to be_present
#   #       expect(Person.count).to eq(1)
#   #       request.headers["Authorization"] = "Token #{api_key.key_string}"
#   #       request.headers["X-VA-Vet-SSN"] = "123456789"
#   #       request.headers["X-VA-File-Number"] = "77799777"
#   #       request.headers["X-VA-Vet-First-Name"] = "John"
#   #       request.headers["X-VA-Vet-Last-Name"] = "Smith"
#   #       request.headers["X-VA-Vet-Middle-Name"] = "Alexander"
#   #       request.headers["X-VA-Claimant-DOB"] = DateTime.now - 30.years
#   #       request.headers["X-VA-Claimant-Email"] = "jim@google.com"
#   #       request.headers["X-VA-Claimant-First-Name"] = "Jimmy"
#   #       request.headers["X-VA-Claimant-Last-Name"] = "Longstocks"
#   #       request.headers["X-VA-Claimant-Middle-Name"] = "Goob"
#   #       request.headers["X-VA-Claimant-SSN"] = "989773212"
#   #       post :decision_review_created, params: valid_params
#   #       expect(response).to have_http_status(:created)
#   #       expect(User.find_by(css_id: "BVADWISE")).to eq(user)
#   #       expect(Veteran.find_by(file_number: "77799777")).to eq(vet)
#   #       expect(Claimant.find_by(participant_id: "1826209")).to be_present
#   #       expect(HigherLevelReview.find_by(veteran_file_number: vet.file_number)).to be_present
#   #       expect(RequestIssue.find_by(contention_reference_id: 7905752)).to be_present
#   #       expect(Person.count).to eq(1)
#   #     end
#   #   end
#   # end

#   describe "POST #decision_review_updated" do
#     let!(:current_user) { User.authenticate! }
#     let(:api_key) { ApiKey.create!(consumer_name: "API TEST TOKEN") }
#     let!(:person) do
#       Person.create(participant_id: "1826209", first_name: "Jimmy", last_name: "Longstocks",
#                     middle_name: "Goob", ssn: "989773212", name_suffix: "")
#     end

#   def json_payload
#     {
#       "event_id": 214706,
#       "claim_id": 1234567,
#       "css_id": "BVADWISE101",
#       "detail_type": "HigherLevelReview",
#       "station": "101",
#       "claim_review": {
#         "informal_conference": false,
#         "same_office": false,
#         "legacy_opt_in_approved": false
#       },
#       "end_product_establishment": {
#         "code": "030HLRR",
#         "development_item_reference_id": "1",
#         "reference_id": "1234567",
#         "synced_status": "RFD",
#         "last_synced_at": 1726688419000
#       },
#       "added_issues": [],
#       "updated_issues": [
#         {
#           "original_caseflow_request_issue_id": 12345,
#           "contested_rating_decision_reference_id": null,
#           "contested_rating_issue_reference_id": null,
#           "contested_decision_issue_id": null,
#           "untimely_exemption": false,
#           "untimely_exemption_notes": null,
#           "edited_description": "DIC: Service connection denied (UPDATED)",
#           "vacols_id": null,
#           "vacols_sequence_id": null,
#           "nonrating_issue_bgs_id": null,
#           "type": "RequestIssue",
#           "decision_review_issue_id": 908,
#           "contention_reference_id": 123456,
#           "benefit_type": "compensation",
#           "contested_issue_description": null,
#           "contested_rating_issue_profile_date": null,
#           "decision_date": null,
#           "ineligible_due_to_id": null,
#           "ineligible_reason": null,
#           "unidentified_issue_text": "An unidentified issue added during the edit",
#           "nonrating_issue_category": null,
#           "nonrating_issue_description": null,
#           "closed_at": null,
#           "closed_status": null,
#           "contested_rating_issue_diagnostic_code": null,
#           "rating_issue_associated_at": null,
#           "ramp_claim_id": null,
#           "is_unidentified": true,
#           "nonrating_issue_bgs_source": null
#         }
#       ],
#       "removed_issues": [],
#       "withdrawn_issues": [],
#       "ineligible_to_eligible_issues": [],
#       "eligible_to_ineligible_issues": [],
#       "ineligible_to_ineligible_issues": []
#     }
#   end

#   let!(:valid_params) do
#     json_payload
#   end

#   describe '#perform!' do
#     it 'updates the existing request issue description' do
#       existing_issue # Ensure the issue is created

#       expect {
#         subject.perform!
#       }.to change { existing_issue.reload.contested_issue_description }
#         .from("Original Description")
#         .to("Updated Description")
#     end
#   end

# end
# end

# # rubocop:enable Style/NumericLiterals

# rubocop:disable Style/NumericLiterals

# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::Events::V1::DecisionReviewUpdatedController, type: :controller do
  describe "POST #decision_review_created" do
    let!(:current_user) { User.authenticate! }
    let(:api_key) { ApiKey.create!(consumer_name: "API TEST TOKEN") }
    let!(:epe) { create(:end_product_establishment, :active_hlr, reference_id: 12345678) }
    let(:review) { create(:higher_level_review) }
    let!(:existing_request_issue) { create(:request_issue, decision_review: review, reference_id: "1234") }

    def json_test_payload
      {
        "event_id": 214786,
        "claim_id": 12345678,
        "css_id": "BVADWISE101",
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
          "legacy_opt_in_approved": false
        },
        "end_product_establishment": {
          "code": "030HLRNR",
          "reference_id": "12345678",
          "last_synced_at": 1702067145000,
          "synced_status": "RFD",
          "development_item_reference_id": "1"
        },
        "updated_issues": [
          {
            "original_caseflow_request_issue_id": 12345,
            "contested_rating_decision_reference_id": 1,
            "contested_rating_issue_reference_id": 2,
            "contested_decision_issue_id": 3,
            "untimely_exemption": false,
            "untimely_exemption_notes": "some notes",
            "edited_description": "DIC: Service connection denied (UPDATED)",
            "vacols_id": "some_id",
            "vacols_sequence_id": "some_sequence_id",
            "nonrating_issue_bgs_id": "some_bgs_id",
            "type": "RequestIssue",
            "decision_review_issue_id": 1234,
            "contention_reference_id": 123456,
            "benefit_type": "compensation",
            "contested_issue_description": "some_description",
            "contested_rating_issue_profile_date": "122255",
            "decision_date": 19_568,
            "ineligible_due_to_id": nil,
            "ineligible_reason": nil,
            "unidentified_issue_text": "An unidentified issue added during the edit",
            "nonrating_issue_category": nil,
            "nonrating_issue_description": nil,
            "closed_at": nil,
            "closed_status": nil,
            "contested_rating_issue_diagnostic_code": "9411",
            "rating_issue_associated_at": nil,
            "ramp_claim_id": nil,
            "is_unidentified": true,
            "nonrating_issue_bgs_source": nil
          }
        ],
        "removed_issues": [],
        "withdrawn_issues": [],
        "ineligible_to_eligible_issues": [],
        "eligible_to_ineligible_issues": [],
        "ineligible_to_ineligible_issues": []
      }
    end

    let!(:valid_params) do
      json_test_payload
    end

    context "updates issue" do
      before do
        allow(FeatureToggle).to receive(:enabled?).with(:disable_ama_eventing).and_return(false)
        request.headers["Authorization"] = "Token token=#{api_key.key_string}"
        request.headers["X-VA-Vet-SSN"] = "123456789"
        request.headers["X-VA-File-Number"] = "77799777"
        request.headers["X-VA-Vet-First-Name"] = "John"
        request.headers["X-VA-Vet-Last-Name"] = "Smith"
        request.headers["X-VA-Vet-Middle-Name"] = "Alexander"
      end

      it "returns success response whith updated edited_description and edited_decision_date" do
        # request.headers["Authorization"] = "Token token=#{api_key.key_string}"
        # request.headers["X-VA-Vet-SSN"] = "123456789"
        # request.headers["X-VA-File-Number"] = "77799777"
        # request.headers["X-VA-Vet-First-Name"] = "John"
        # request.headers["X-VA-Vet-Last-Name"] = "Smith"
        # request.headers["X-VA-Vet-Middle-Name"] = "Alexander"
        post :decision_review_updated, params: valid_params
        expect(response).to have_http_status(:ok)
      end
    end
  end
end

# rubocop:enable Style/NumericLiterals
