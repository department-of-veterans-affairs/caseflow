# frozen_string_literal: true

# create vbms-ext-claim seeds
module Seeds

  class VbmsExtClaim < Base
    def seed!
      # create_vbms_ext_claims_with_no_end_product_establishment
      # create_in_sync_epes_and_vbms_ext_claims
      create_out_of_sync_epes_and_vbms_ext_claims
    end

	 private

	def create_out_of_sync_epes_and_vbms_ext_claims
    # 25 High Level Review, End Product Establishments that have a sync_status of cleared and are out_of_sync with
    # vbms_ext_claims
    25.times do |n|
      # out_of_sync vbms_ext_claim LEVEL_STATUS_CODE "CAN"
      vec = create(:vbms_ext_claim, :canceled)
      veteran = create(:veteran)
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
              veteran_file_number: veteran.file_number,
              claimant_participant_id: veteran.participant_id)

    end
    # 25 High Level Review, End Product Establishments that have a sync_status of canceled and are out_of_sync with
    # vbms_ext_claims
    25.times do |n|
      # out_of_sync vbms_ext_claim LEVEL_STATUS_CODE "CLR"
      vec = create(:vbms_ext_claim, :cleared)
      veteran = create(:veteran)
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
              veteran_file_number: veteran.file_number,
              claimant_participant_id: veteran.participant_id)

    end
    # # 25 Supplemental Claims, End Product Establishments that have a sync_status of cleared and are out_of_sync with
    # # vbms_ext_claims
    25.times do |n|
      # out_of_sync vbms_ext_claim LEVEL_STATUS_CODE "CAN"
      vec = create(:vbms_ext_claim, :canceled)
      veteran = create(:veteran)
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
              veteran_file_number: veteran.file_number,
              claimant_participant_id: veteran.participant_id)

    end

    # # 25 Supplemental Claims, End Product Establishments that have a sync_status of canceled and are in_sync with
    # # vbms_ext_claims
    25.times do |n|
      # out_of_sync vbms_ext_claim LEVEL_STATUS_CODE "CLR"
      vec = create(:vbms_ext_claim, :cleared)
      veteran = create(:veteran)
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
              veteran_file_number: veteran.file_number,
              claimant_participant_id: veteran.participant_id)

    end


	end

	def create_in_sync_epes_and_vbms_ext_claims


	end

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
