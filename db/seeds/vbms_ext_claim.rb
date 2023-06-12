# frozen_string_literal: true

# create vbms-ext-claim seeds
module Seeds

  class VbmsExtClaim < Base
    # creates and seeds 325 total vbms_ext_claims
    def seed!
      create_vbms_ext_claims_with_no_end_product_establishment
      create_in_sync_epes_and_vbms_ext_claims
      create_out_of_sync_epes_and_vbms_ext_claims
    end

	 private

  # creates out_of_sync vbms_ext_claims and end_produdct_establishments
	def create_out_of_sync_epes_and_vbms_ext_claims
    # 25 High Level Review, End Product Establishments that have a sync_status of cleared and are out_of_sync with
    # vbms_ext_claims
    25.times do
      veteran = create(:veteran)
      # out_of_sync vbms_ext_claim LEVEL_STATUS_CODE "CAN"
      vec = create(:vbms_ext_claim,
                   :canceled,
                   :hlr,
                   claimant_person_id: veteran.participant_id)
      higher_level_review = create(:higher_level_review,
                                    veteran_file_number: veteran.file_number)
      eligible_request_issue = create(:request_issue,
                                      decision_review: higher_level_review,
                                      nonrating_issue_category: "Military Retired Pay",
                                      nonrating_issue_description: "nonrating description",
                                      ineligible_reason: nil,
                                      benefit_type: "compensation",
                                      decision_date: Date.new(2018, 5, 1))
      create(:end_product_establishment,
             :active,
              source: higher_level_review,
              reference_id: vec.claim_id,
              established_at: vec.establishment_date,
              claim_date: vec.claim_date,
              modifier: vec.ep_code,
              code: vec.type_code,
              veteran_file_number: veteran.file_number,
              claimant_participant_id: veteran.participant_id)
    end
    # 25 High Level Review, End Product Establishments that have a sync_status of canceled and are out_of_sync with
    # vbms_ext_claims
    25.times do
      veteran = create(:veteran)
      # out_of_sync vbms_ext_claim LEVEL_STATUS_CODE "CLR"
      vec = create(:vbms_ext_claim,
                   :cleared,
                   :hlr,
                   claimant_person_id: veteran.participant_id)
      higher_level_review = create(:higher_level_review,
                                    veteran_file_number: veteran.file_number)
      eligible_request_issue = create(:request_issue,
                                      decision_review: higher_level_review,
                                      nonrating_issue_category: "Military Retired Pay",
                                      nonrating_issue_description: "nonrating description",
                                      ineligible_reason: nil,
                                      benefit_type: "compensation",
                                      decision_date: Date.new(2018, 5, 1))
      create(:end_product_establishment,
             :active,
             source: higher_level_review,
             reference_id: vec.claim_id,
             established_at: vec.establishment_date,
             claim_date: vec.claim_date,
             modifier: vec.ep_code,
             code: vec.type_code,
             veteran_file_number: veteran.file_number,
             claimant_participant_id: veteran.participant_id)
    end
    # # 25 Supplemental Claims, End Product Establishments that have a sync_status of cleared and are out_of_sync with
    # # vbms_ext_claims
    25.times do
      veteran = create(:veteran)
      # out_of_sync vbms_ext_claim LEVEL_STATUS_CODE "CAN"
      vec = create(:vbms_ext_claim,
                   :cleared,
                   :slc,
                   claimant_person_id: veteran.participant_id)
      supplemental_claim = create(:supplemental_claim,
            veteran_file_number: veteran.file_number,
            receipt_date: Time.zone.now,
            benefit_type: "compensation")
      eligible_request_issue = create(:request_issue,
                                      decision_review: supplemental_claim,
                                      nonrating_issue_category: "Military Retired Pay",
                                      nonrating_issue_description: "nonrating description",
                                      ineligible_reason: nil,
                                      benefit_type: "compensation",
                                      decision_date: Date.new(2018, 5, 1))
      create(:end_product_establishment,
             :active,
             source: supplemental_claim,
             reference_id: vec.claim_id,
             established_at: vec.establishment_date,
             claim_date: vec.claim_date,
             modifier: vec.ep_code,
             code: vec.type_code,
             veteran_file_number: veteran.file_number,
             claimant_participant_id: veteran.participant_id)
    end

    # # 25 Supplemental Claims, End Product Establishments that have a sync_status of canceled and are out_of_sync with
    # # vbms_ext_claims
    25.times do
      veteran = create(:veteran)
      # out_of_sync vbms_ext_claim LEVEL_STATUS_CODE "CLR"
      vec = create(:vbms_ext_claim,
                   :cleared,
                   :slc,
                   claimant_person_id: veteran.participant_id)
      supplemental_claim = create(:supplemental_claim,
            veteran_file_number: veteran.file_number,
            receipt_date: Time.zone.now,
            benefit_type: "compensation")
      eligible_request_issue = create(:request_issue,
                                      decision_review: supplemental_claim,
                                      nonrating_issue_category: "Military Retired Pay",
                                      nonrating_issue_description: "nonrating description",
                                      ineligible_reason: nil,
                                      benefit_type: "compensation",
                                      decision_date: Date.new(2018, 5, 1))
      create(:end_product_establishment,
             :active,
             source: supplemental_claim,
             reference_id: vec.claim_id,
             established_at: vec.establishment_date,
             claim_date: vec.claim_date,
             modifier: vec.ep_code,
             code: vec.type_code,
             veteran_file_number: veteran.file_number,
             claimant_participant_id: veteran.participant_id)
    end
	end

  # creates in_sync vbms_ext_claims and end_produdct_establishments
	def create_in_sync_epes_and_vbms_ext_claims
    # 25 High Level Review, End Product Establishments that have a sync_status of canceled and are in_sync with
    # vbms_ext_claims
    25.times do
      veteran = create(:veteran)
      # in_sync vbms_ext_claim LEVEL_STATUS_CODE "CAN"
      vec = create(:vbms_ext_claim,
                   :canceled,
                   :hlr,
                   claimant_person_id: veteran.participant_id)
      higher_level_review = create(:higher_level_review,
                                    veteran_file_number: veteran.file_number)
      eligible_request_issue = create(:request_issue,
                                      decision_review: higher_level_review,
                                      nonrating_issue_category: "Military Retired Pay",
                                      nonrating_issue_description: "nonrating description",
                                      ineligible_reason: nil,
                                      benefit_type: "compensation",
                                      decision_date: Date.new(2018, 5, 1))
      create(:end_product_establishment,
             :canceled,
              source: higher_level_review,
              reference_id: vec.claim_id,
              established_at: vec.establishment_date,
              claim_date: vec.claim_date,
              modifier: vec.ep_code,
              code: vec.type_code,
              veteran_file_number: veteran.file_number,
              claimant_participant_id: veteran.participant_id)
    end
    # 25 High Level Review, End Product Establishments that have a sync_status of cleared and are in_sync with
    # vbms_ext_claims
    25.times do
      veteran = create(:veteran)
      # in_sync vbms_ext_claim LEVEL_STATUS_CODE "CLR"
      vec = create(:vbms_ext_claim,
                   :cleared,
                   :hlr,
                   claimant_person_id: veteran.participant_id)
      higher_level_review = create(:higher_level_review,
                                    veteran_file_number: veteran.file_number)
      eligible_request_issue = create(:request_issue,
                                      decision_review: higher_level_review,
                                      nonrating_issue_category: "Military Retired Pay",
                                      nonrating_issue_description: "nonrating description",
                                      ineligible_reason: nil,
                                      benefit_type: "compensation",
                                      decision_date: Date.new(2018, 5, 1))
      create(:end_product_establishment,
             :cleared,
             source: higher_level_review,
             reference_id: vec.claim_id,
             established_at: vec.establishment_date,
             claim_date: vec.claim_date,
             modifier: vec.ep_code,
             code: vec.type_code,
             veteran_file_number: veteran.file_number,
             claimant_participant_id: veteran.participant_id)
    end
    # # 25 Supplemental Claims, End Product Establishments that have a sync_status of cleared and are in_sync with
    # # vbms_ext_claims
    25.times do
      veteran = create(:veteran)
      # in_sync vbms_ext_claim LEVEL_STATUS_CODE "CLR"
      vec = create(:vbms_ext_claim,
                   :cleared,
                   :slc,
                   claimant_person_id: veteran.participant_id)
      supplemental_claim = create(:supplemental_claim,
            veteran_file_number: veteran.file_number,
            receipt_date: Time.zone.now,
            benefit_type: "compensation")
      eligible_request_issue = create(:request_issue,
                                      decision_review: supplemental_claim,
                                      nonrating_issue_category: "Military Retired Pay",
                                      nonrating_issue_description: "nonrating description",
                                      ineligible_reason: nil,
                                      benefit_type: "compensation",
                                      decision_date: Date.new(2018, 5, 1))
      create(:end_product_establishment,
             :cleared,
             source: supplemental_claim,
             reference_id: vec.claim_id,
             established_at: vec.establishment_date,
             claim_date: vec.claim_date,
             modifier: vec.ep_code,
             code: vec.type_code,
             veteran_file_number: veteran.file_number,
             claimant_participant_id: veteran.participant_id)
    end

    # # 25 Supplemental Claims, End Product Establishments that have a sync_status of canceled and are out_sync with
    # # vbms_ext_claims
    25.times do
      veteran = create(:veteran)
      # in_sync vbms_ext_claim LEVEL_STATUS_CODE "CAN"
      vec = create(:vbms_ext_claim,
                   :canceled,
                   :slc,
                   claimant_person_id: veteran.participant_id)
      supplemental_claim = create(:supplemental_claim,
            veteran_file_number: veteran.file_number,
            receipt_date: Time.zone.now,
            benefit_type: "compensation")
      eligible_request_issue = create(:request_issue,
                                      decision_review: supplemental_claim,
                                      nonrating_issue_category: "Military Retired Pay",
                                      nonrating_issue_description: "nonrating description",
                                      ineligible_reason: nil,
                                      benefit_type: "compensation",
                                      decision_date: Date.new(2018, 5, 1))
      create(:end_product_establishment,
             :canceled,
             source: supplemental_claim,
             reference_id: vec.claim_id,
             established_at: vec.establishment_date,
             claim_date: vec.claim_date,
             modifier: vec.ep_code,
             code: vec.type_code,
             veteran_file_number: veteran.file_number,
             claimant_participant_id: veteran.participant_id)
    end
	end

  # creates 124 vbms_ext_claims not associated with an end_product_establishment
	def create_vbms_ext_claims_with_no_end_product_establishment
    # creates 50 none epe assocated vbms_ext_claims with LEVEL_STATUS_CODE "CLR"
    50.times do
      create(:vbms_ext_claim, :cleared)
    end
     # creates 50 none epe assocated vbms_ext_claims with LEVEL_STATUS_CODE "CAN"
    50.times do
      create(:vbms_ext_claim,:canceled)
    end
     # creates 50 none epe assocated vbms_ext_claims with LEVEL_STATUS_CODE "RDC"
    25.times do
      create(:vbms_ext_claim,:rdc)
    end
	end
 end
end
