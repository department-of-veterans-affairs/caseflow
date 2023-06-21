# frozen_string_literal: true

# create vbms claims
module Seeds

  class VbmsExtClaim < Base


    def initialize
      file_number_initial_value
    end
    ##
    # creates and seeds 325 total vbms_ext_claims
    # The number of claims created are subject to change in order to meet testing requirements
    ##
    def seed!
      create_vbms_ext_claims_with_no_end_product_establishment
      create_in_sync_epes_and_vbms_ext_claims
      create_out_of_sync_epes_and_vbms_ext_claims
    end

private

 # maintains previous file number values while allowing for reseeding
 def file_number_initial_value
  @file_number ||= 300_000
  # this seed file creates 200 new veterans on each run, 250 is sufficient margin to add more data
  @file_number += 250 while Veteran.find_by(file_number: format("%<n>09d", n: @file_number))
  @file_number
  end

  ##
  # this out_of_sync method creates and seeds Vbms_Ext_Claims that have a Level_Status_Code DIFFERENT then the
  # End_Product_Establishment sync_status in order to test the sync_job and batch_job that finds differences between
  # VbmsExtClaim associated with the End Product Establishment
  ##
	def create_out_of_sync_epes_and_vbms_ext_claims
    # 25 High Level Review, End Product Establishments that have a sync_status of cleared and are out_of_sync with
    # vbms_ext_claims
    25.times do
      veteran = create(:veteran, file_number: format("%<n>09d", n: @file_number))
      @file_number += 1
      # out_of_sync vbms_ext_claim LEVEL_STATUS_CODE "CAN"
      vec = create(:vbms_ext_claim,
                   :canceled,
                   :hlr,
                   claimant_person_id: veteran.participant_id)
      higher_level_review = create(:higher_level_review,
                                    veteran_file_number: veteran.file_number)
      create(:request_issue,
              decision_review: higher_level_review,
              nonrating_issue_category: "Military Retired Pay",
              nonrating_issue_description: "nonrating description",
              ineligible_reason: nil,
              benefit_type: "compensation",
              decision_date: Date.new(2018, 5, 1))
      create(:request_issue,
              decision_review: higher_level_review,
              nonrating_issue_category: "Active Duty Adjustments",
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
      veteran = create(:veteran, file_number: format("%<n>09d", n: @file_number))
      @file_number += 1
      # out_of_sync vbms_ext_claim LEVEL_STATUS_CODE "CLR"
      vec = create(:vbms_ext_claim,
                   :cleared,
                   :hlr,
                   claimant_person_id: veteran.participant_id)
      higher_level_review = create(:higher_level_review,
                                    veteran_file_number: veteran.file_number)
      create(:request_issue,
              decision_review: higher_level_review,
              nonrating_issue_category: "Military Retired Pay",
              nonrating_issue_description: "nonrating description",
              ineligible_reason: nil,
              benefit_type: "compensation",
              decision_date: Date.new(2018, 5, 1))
      create(:request_issue,
              decision_review: higher_level_review,
              nonrating_issue_category: "Active Duty Adjustments",
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
      veteran = create(:veteran, file_number: format("%<n>09d", n: @file_number))
      @file_number += 1
      # out_of_sync vbms_ext_claim LEVEL_STATUS_CODE "CAN"
      vec = create(:vbms_ext_claim,
                   :cleared,
                   :slc,
                   claimant_person_id: veteran.participant_id)
      supplemental_claim = create(:supplemental_claim,
            veteran_file_number: veteran.file_number,
            receipt_date: Time.zone.now,
            benefit_type: "compensation")
      create(:request_issue,
              decision_review: supplemental_claim,
              nonrating_issue_category: "Military Retired Pay",
              nonrating_issue_description: "nonrating description",
              ineligible_reason: nil,
              benefit_type: "compensation",
              decision_date: Date.new(2018, 5, 1))
      create(:request_issue,
              decision_review: supplemental_claim,
              nonrating_issue_category: "Active Duty Adjustments",
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
      veteran = create(:veteran, file_number: format("%<n>09d", n: @file_number))
      @file_number += 1
      # out_of_sync vbms_ext_claim LEVEL_STATUS_CODE "CLR"
      vec = create(:vbms_ext_claim,
                   :cleared,
                   :slc,
                   claimant_person_id: veteran.participant_id)
      supplemental_claim = create(:supplemental_claim,
            veteran_file_number: veteran.file_number,
            receipt_date: Time.zone.now,
            benefit_type: "compensation")
      create(:request_issue,
              decision_review: supplemental_claim,
              nonrating_issue_category: "Military Retired Pay",
              nonrating_issue_description: "nonrating description",
              ineligible_reason: nil,
              benefit_type: "compensation",
              decision_date: Date.new(2018, 5, 1))
      create(:request_issue,
              decision_review: supplemental_claim,
              nonrating_issue_category: "Active Duty Adjustments",
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

  ##
  # this in_sync method creates and seeds Vbms_Ext_Claims that have a Level_Status_Code matching the
  # End_Product_Establishment sync_status in order to test the sync_job and batch_job that finds differences between
  # VbmsExtClaim associated with the End Product Establishment. Both jobs should skip these objects because
  # Level_Status_Code matches the sync_status
  ##
	def create_in_sync_epes_and_vbms_ext_claims
    # 25 High Level Review, End Product Establishments that have a sync_status of canceled and are in_sync with
    # vbms_ext_claims
    25.times do
      veteran = create(:veteran, file_number: format("%<n>09d", n: @file_number))
      @file_number += 1
      # in_sync vbms_ext_claim LEVEL_STATUS_CODE "CAN"
      vec = create(:vbms_ext_claim,
                   :canceled,
                   :hlr,
                   claimant_person_id: veteran.participant_id)
      higher_level_review = create(:higher_level_review,
                                    veteran_file_number: veteran.file_number)
      create(:request_issue,
              decision_review: higher_level_review,
              nonrating_issue_category: "Military Retired Pay",
              nonrating_issue_description: "nonrating description",
              ineligible_reason: nil,
              benefit_type: "compensation",
              decision_date: Date.new(2018, 5, 1))
      create(:request_issue,
              decision_review: higher_level_review,
              nonrating_issue_category: "Active Duty Adjustments",
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
      veteran = create(:veteran, file_number: format("%<n>09d", n: @file_number))
      @file_number += 1
      # in_sync vbms_ext_claim LEVEL_STATUS_CODE "CLR"
      vec = create(:vbms_ext_claim,
                   :cleared,
                   :hlr,
                   claimant_person_id: veteran.participant_id)
      higher_level_review = create(:higher_level_review,
                                    veteran_file_number: veteran.file_number)
      create(:request_issue,
              decision_review: higher_level_review,
              nonrating_issue_category: "Military Retired Pay",
              nonrating_issue_description: "nonrating description",
              ineligible_reason: nil,
              benefit_type: "compensation",
              decision_date: Date.new(2018, 5, 1))
      create(:request_issue,
              decision_review: higher_level_review,
              nonrating_issue_category: "Active Duty Adjustments",
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
      veteran = create(:veteran, file_number: format("%<n>09d", n: @file_number))
      @file_number += 1
      # in_sync vbms_ext_claim LEVEL_STATUS_CODE "CLR"
      vec = create(:vbms_ext_claim,
                   :cleared,
                   :slc,
                   claimant_person_id: veteran.participant_id)
      supplemental_claim = create(:supplemental_claim,
            veteran_file_number: veteran.file_number,
            receipt_date: Time.zone.now,
            benefit_type: "compensation")
      create(:request_issue,
              decision_review: supplemental_claim,
              nonrating_issue_category: "Military Retired Pay",
              nonrating_issue_description: "nonrating description",
              ineligible_reason: nil,
              benefit_type: "compensation",
              decision_date: Date.new(2018, 5, 1))
      create(:request_issue,
              decision_review: supplemental_claim,
              nonrating_issue_category: "Active Duty Adjustments",
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
      veteran = create(:veteran, file_number: format("%<n>09d", n: @file_number))
      @file_number += 1
      # in_sync vbms_ext_claim LEVEL_STATUS_CODE "CAN"
      vec = create(:vbms_ext_claim,
                   :canceled,
                   :slc,
                   claimant_person_id: veteran.participant_id)
      supplemental_claim = create(:supplemental_claim,
            veteran_file_number: veteran.file_number,
            receipt_date: Time.zone.now,
            benefit_type: "compensation")
      create(:request_issue,
              decision_review: supplemental_claim,
              nonrating_issue_category: "Military Retired Pay",
              nonrating_issue_description: "nonrating description",
              ineligible_reason: nil,
              benefit_type: "compensation",
              decision_date: Date.new(2018, 5, 1))
      create(:request_issue,
              decision_review: supplemental_claim,
              nonrating_issue_category: "Active Duty Adjustments",
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
  ##
  # this method creates VBMS_EXT_CLAIMS that have yet to be Established in CASEFLOW to mimic
  # the VBMS API CALL. The VBMS_EXT_CLAIMS have no assocations to an End Product Establishment.
  ##
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
