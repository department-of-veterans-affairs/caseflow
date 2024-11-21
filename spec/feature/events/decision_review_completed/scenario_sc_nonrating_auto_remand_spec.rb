# frozen_string_literal: true

require "rails_helper"

RSpec.describe Api::Events::V1::DecisionReviewCompletedController, type: :controller do
  describe "POST #decision_review_completed" do
    let!(:current_user) { User.authenticate! }
    let(:api_key) { ApiKey.create!(consumer_name: "API TEST TOKEN") }
    # let!(:epe) { create(:end_product_establishment, :active_hlr, reference_id: 337_534) }
    # let(:review) { epe.source }
    # let!(:existing_request_issue) { create(:request_issue, :ineligible, decision_review: review, reference_id: "1234")}

    def json_test_payload
      {
        "event_id": "1",
        "css_id": "BVADWISE",
        "detail_type": "SupplementalClaim",
        "station": "101",
        "intake": {
          "started_at": 1_702_067_143_435,
          "completion_started_at": 1_702_067_145_000,
          "completed_at": 1_702_067_145_000,
          "completion_status": "success",
          "type": "SupplementalClaimIntake",
          "detail_type": "SupplementalClaim"
        },
        "veteran": {
          "participant_id": "1826209",
          "bgs_last_synced_at": 1_708_533_584_000,
          "name_suffix": null,
          "date_of_death": null
        },
        "claimant": {
          "payee_code": "00",
          "type": "VeteranClaimant",
          "participant_id": "1826209",
          "name_suffix": null
        },
        "claim_review": {
          "auto_remand": true,
          "benefit_type": "compensation",
          "filed_by_va_gov": false,
          "legacy_opt_in_approved": false,
          "receipt_date": 19_594,
          "veteran_is_not_claimant": false,
          "establishment_attempted_at": 1_702_067_145_000,
          "establishment_last_submitted_at": 1_702_067_145_000,
          "establishment_processed_at": 1_702_067_145_000,
          "establishment_submitted_at": 1_702_067_145_000,
          "informal_conference": false,
          "same_office": false
        },
        "end_product_establishment": {
          "benefit_type_code": "1",
          "claim_date": 19_594,
          "code": "040HDENR",
          "modifier": "040",
          "payee_code": "00",
          "reference_id": "337534",
          "limited_poa_access": null,
          "limited_poa_code": null,
          "committed_at": 1_702_067_145_000,
          "established_at": 1_702_067_145_000,
          "last_synced_at": 1_702_067_145_000,
          "synced_status": "RW",
          "development_item_reference_id": null
        },
        "request_issues": [
          {
            "decision_review_issue_id": "1234",
            "benefit_type": "compensation",
            "contested_issue_description": null,
            "contention_reference_id": 7_905_752,
            "contested_rating_decision_reference_id": null,
            "contested_rating_issue_profile_date": null,
            "contested_rating_issue_reference_id": null,
            "contested_decision_issue_id": null,
            "decision_date": 18_475,
            "ineligible_due_to_id": null,
            "ineligible_reason": null,
            "is_unidentified": false,
            "unidentified_issue_text": null,
            "nonrating_issue_category": "DEPENDENCY",
            "nonrating_issue_description": "DTA Error - Other Recs: Dependency: Wendy Boyd,
                                            Not an Award Dependent, Turns 18, effective 01/01/2024",
            "remand_source_id": 1234,
            "untimely_exemption": null,
            "untimely_exemption_notes": null,
            "vacols_id": null,
            "vacols_sequence_id": null,
            "closed_at": null,
            "closed_status": null,
            "contested_rating_issue_diagnostic_code": 5000,
            "ramp_claim_id": null,
            "rating_issue_associated_at": null,
            "nonrating_issue_bgs_id": "13",
            "nonrating_issue_bgs_source": "CORP_AWARD_ATTORNEY_FEE"
          }
        ]
      }
    end

    let!(:valid_params) do
      json_test_payload
    end

    context "updates issue nonrating_sc_auto_remand" do
      before do
        request.headers["Authorization"] = "Token token=#{api_key.key_string}"
      end

      it "returns success response nonrating_sc_auto_remand" do
        # expect(existing_request_issue.edited_description).to_not eq("DIC: Service connection denied (UPDATED)")
        post :decision_review_completed, params: valid_params
        expect(response).to have_http_status(:completed)
        expect(response.body).to include("DecisionReviewcompletedEvent successfully processed")
        existing_request_issue.reload
        completed_request_issue = RequestIssue.find_by(reference_id: "1234")
        expect(completed_request_issue.nonrating_issue_category).to eq("DEPENDENCY")
        expect(completed_request_issue.nonrating_issue_description).to eq("DTA Error - Other Recs: Dependency:
                                                                          Wendy Boyd, Not an Award Dependent,
                                                                          Turns 18, effective 01/01/2024")
        expect(completed_request_issue.nonrating_issue_bgs_source).to eq("CORP_AWARD_ATTORNEY_FEE")
        expect(completed_request_issue.nonrating_issue_bgs_id).to eq("13")
        expect(completed_request_issue.rating_issue_associated_at).to eq(nil)
        expect(completed_request_issue.contested_issue_description).to eq(nil)
        expect(completed_request_issue.contention_reference_id).to eq(7_905_752)
        expect(completed_request_issue.contested_rating_decision_reference_id).to eq(nil)
        expect(completed_request_issue.contested_rating_issue_profile_date).to eq(nil)
        expect(completed_request_issue.contested_rating_issue_reference_id).to eq(nil)
        expect(completed_request_issue.closed_at).to eq(nil)
        expect(completed_request_issue.closed_status).to eq(nil)
        expect(completed_request_issue.vacols_id).to eq(nil)
        expect(completed_request_issue.vacols_sequence_id).to eq(nil)
        epe = EndProductEstablishment.find_by(reference_id: "337534")
        review = epe.source
        veteran = epe.veteran
        id = epe.claimant_participant_id
        claimant = Claimant.find_by(participant_id: id)
        expect(epe.synced_status).to eq("RW")
        expect(epe.limited_poa_access).to eq(nil)
        expect(epe.limited_poa_code).to eq(nil)
        expect(veteran.participant_id).to eq("1826209")
        expect(veteran.bgs_last_synced_at).to eq(1_708_533_584_000)
        expect(veteran.bgs_last_synced_at).to eq(1_708_533_584_000)
        expect(veteran.name_suffix).to eq(nil)
        expect(veteran.date_of_death).to eq(nil)
        expect(review.auto_remand).to eq(true)
        expect(review.establishment_attempted_at).to eq(1_702_067_145_000)
        expect(review.establishment_last_submitted_at).to eq(1_702_067_145_000)
        expect(review.establishment_processed_at).to eq(1_702_067_145_000)
        expect(review.establishment_submitted_at).to eq(1_702_067_145_000)
        expect(review.informal_conference).to eq(false)
        expect(review.same_office).to eq(false)
        expect(review.legacy_opt_in_approved).to eq(false)
        expect(claimant.type).to eq("VeteranClaimant")
        expect(claimant.payee_code).to eq("00")
        expect(claimant.participant_id).to eq("1826209")
      end
    end

    # context "updated issue with other issues already on the review" do
    #   let!(:existing_request_issue_2) { create(:request_issue, decision_review: review, reference_id: "6789") }
    #   before do
    #     request.headers["Authorization"] = "Token token=#{api_key.key_string}"
    #   end

    #   it "returns success response whith updated edited_description" do
    #     expect(RequestIssue.find_by(reference_id: "6789")).to be
    #     expect(existing_request_issue.edited_description).to_not eq("DIC: Service connection denied (UPDATED)")
    #     post :decision_review_updated, params: valid_params
    #     expect(response).to have_http_status(:created)
    #     expect(response.body).to include("DecisionReviewUpdatedEvent successfully processed")
    #     existing_request_issue.reload
    #     expect(existing_request_issue.edited_description).to eq("DIC: Service connection denied (UPDATED)")
    #     expect(existing_request_issue.any_updates?).to eq(true)
    #     expect(RequestIssue.find_by(reference_id: "6789")).to be
    #     request_issue_update = review.request_issues_updates.first
    #     expect(request_issue_update).to be
    #     expect(request_issue_update.before_request_issue_ids).to eq(
    #       [existing_request_issue.id, existing_request_issue_2.id]
    #     )
    #     expect(request_issue_update.after_request_issue_ids).to eq(
    #       [existing_request_issue.id, existing_request_issue_2.id]
    #     )
    #     expect(request_issue_update.withdrawn_request_issue_ids).to eq([])
    #     expect(request_issue_update.edited_request_issue_ids).to eq([existing_request_issue.id])
    #   end
    # end

    # context "does not update on error" do
    #   before do
    #     request.headers["Authorization"] = "Token token=#{api_key.key_string}"
    #     allow_any_instance_of(RequestIssuesUpdateEvent).to receive(:perform!).and_raise(StandardError.new("Error"))
    #   end

    #   it "returns success response whith updated edited_description" do
    #     expect(existing_request_issue.edited_description).to_not eq("DIC: Service connection denied (UPDATED)")
    #     post :decision_review_updated, params: valid_params
    #     expect(response).to have_http_status(:unprocessable_entity)
    #     expect(response.body).to include("Error")
    #     existing_request_issue.reload
    #     expect(existing_request_issue.edited_description).to_not eq("DIC: Service connection denied (UPDATED)")
    #     expect(existing_request_issue.any_updates?).to eq(false)
    #   end
    # end

    # context "updates multiple issues with already existing issues not edited" do
    #   let!(:existing_request_issue_2) { create(:request_issue, decision_review: review, reference_id: "6789") }
    #   let!(:existing_request_issue_3) { create(:request_issue, decision_review: review, reference_id: "123456789") }
    #   before do
    #     request.headers["Authorization"] = "Token token=#{api_key.key_string}"
    #     valid_params[:updated_issues] << {
    #       "original_caseflow_request_issue_id": 2,
    #       "contested_rating_decision_reference_id": 1,
    #       "contested_rating_issue_reference_id": 2,
    #       "contested_decision_issue_id": nil,
    #       "untimely_exemption": false,
    #       "untimely_exemption_notes": "some notes",
    #       "edited_description": "DIC: Service connection denied 2 (UPDATED)",
    #       "vacols_id": "some_id",
    #       "vacols_sequence_id": "some_sequence_id",
    #       "nonrating_issue_bgs_id": "some_bgs_id",
    #       "type": "RequestIssue",
    #       "decision_review_issue_id": 6789,
    #       "contention_reference_id": 123_456,
    #       "benefit_type": "compensation",
    #       "contested_issue_description": "some_description",
    #       "contested_rating_issue_profile_date": "122255",
    #       "decision_date": 19_568,
    #       "ineligible_due_to_id": nil,
    #       "ineligible_reason": nil,
    #       "unidentified_issue_text": "An unidentified issue added during the edit",
    #       "nonrating_issue_category": nil,
    #       "nonrating_issue_description": nil,
    #       "closed_at": nil,
    #       "closed_status": nil,
    #       "contested_rating_issue_diagnostic_code": "9411",
    #       "rating_issue_associated_at": nil,
    #       "ramp_claim_id": nil,
    #       "is_unidentified": true,
    #       "nonrating_issue_bgs_source": nil
    #     }
    #   end

    #   it "returns success response with updated edited_description" do
    #     expect(existing_request_issue.edited_description).to_not eq("DIC: Service connection denied (UPDATED)")
    #     expect(existing_request_issue_2.edited_description).to_not eq("DIC: Service connection denied 2 (UPDATED)")
    #     post :decision_review_updated, params: valid_params
    #     expect(response).to have_http_status(:created)
    #     expect(response.body).to include("DecisionReviewUpdatedEvent successfully processed")
    #     existing_request_issue.reload
    #     existing_request_issue_2.reload
    #     expect(existing_request_issue.edited_description).to eq("DIC: Service connection denied (UPDATED)")
    #     expect(existing_request_issue.any_updates?).to eq(true)
    #     expect(existing_request_issue_2.edited_description).to eq("DIC: Service connection denied 2 (UPDATED)")
    #     expect(existing_request_issue_2.any_updates?).to eq(true)
    #     expect(RequestIssue.find_by(reference_id: "123456789")).to be
    #     request_issue_update = review.request_issues_updates.first
    #     expect(request_issue_update).to be
    #     expect(request_issue_update.before_request_issue_ids).to eq(
    #       [existing_request_issue.id, existing_request_issue_2.id, existing_request_issue_3.id]
    #     )
    #     expect(request_issue_update.after_request_issue_ids).to eq(
    #       [existing_request_issue.id, existing_request_issue_2.id, existing_request_issue_3.id]
    #     )
    #     expect(request_issue_update.withdrawn_request_issue_ids).to eq([])
    #     expect(request_issue_update.edited_request_issue_ids).to eq(
    #       [existing_request_issue.id, existing_request_issue_2.id]
    #     )
    #   end
    # end
  end
end
