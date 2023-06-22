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
      vbms_ext_claim = create_vbms_ext_claim(veteran, :canceled, :hlr)
      higher_level_review = create_high_level_review(veteran)
			# out_of_sync end_product_establishment sync_status "PEND"
			end_product_establishment = create_end_product_establishment(higher_level_review, :active, vbms_ext_claim, veteran)

			create_request_issue(higher_level_review, end_product_establishment, "Military Retired Pay")
			create_request_issue(higher_level_review, end_product_establishment, "Active Duty Adjustments")
		end

    # 25 High Level Review, End Product Establishments that have a sync_status of canceled and are out_of_sync with
    # vbms_ext_claims
    25.times do
      veteran = create(:veteran, file_number: format("%<n>09d", n: @file_number))
      @file_number += 1
      # out_of_sync vbms_ext_claim LEVEL_STATUS_CODE "CLR"
			vbms_ext_claim = create_vbms_ext_claim(veteran, :cleared, :hlr)
			higher_level_review = create_high_level_review(veteran)
			# out_of_sync end_product_establishment sync_status "PEND"
			end_product_establishment = create_end_product_establishment(higher_level_review, :active, vbms_ext_claim, veteran)

      create_request_issue(higher_level_review, end_product_establishment, "Military Retired Pay")
			create_request_issue(higher_level_review, end_product_establishment, "Active Duty Adjustments")
    end

    # # 25 Supplemental Claims, End Product Establishments that have a sync_status of cleared and are out_of_sync with
    # # vbms_ext_claims
    25.times do
      veteran = create(:veteran, file_number: format("%<n>09d", n: @file_number))
      @file_number += 1
      # out_of_sync vbms_ext_claim LEVEL_STATUS_CODE "CAN"
			vbms_ext_claim = create_vbms_ext_claim(veteran, :canceled, :slc)
      supplemental_claim = create_supplemental_claim(veteran)
			# out_of_sync end_product_establishment sync_status "PEND"
			end_product_establishment = create_end_product_establishment(supplemental_claim, :active, vbms_ext_claim, veteran)

      create_request_issue(supplemental_claim, end_product_establishment, "Military Retired Pay")
			create_request_issue(supplemental_claim, end_product_establishment, "Active Duty Adjustments")
    end

    # # 25 Supplemental Claims, End Product Establishments that have a sync_status of canceled and are out_of_sync with
    # # vbms_ext_claims
    25.times do
      veteran = create(:veteran, file_number: format("%<n>09d", n: @file_number))
      @file_number += 1
      # out_of_sync vbms_ext_claim LEVEL_STATUS_CODE "CLR"
			vbms_ext_claim = create_vbms_ext_claim(veteran, :cleared, :slc)
      supplemental_claim = create_supplemental_claim(veteran)
			# out_of_sync end_product_establishment sync_status "PEND"
			end_product_establishment = create_end_product_establishment(supplemental_claim, :active, vbms_ext_claim, veteran)

      create_request_issue(supplemental_claim, end_product_establishment, "Military Retired Pay")
			create_request_issue(supplemental_claim, end_product_establishment, "Active Duty Adjustments")
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
			vbms_ext_claim = create_vbms_ext_claim(veteran, :canceled, :hlr)
			higher_level_review = create_high_level_review(veteran)
			end_product_establishment = create_end_product_establishment(higher_level_review,:canceled, vbms_ext_claim, veteran)

			create_request_issue(higher_level_review, end_product_establishment, "Military Retired Pay")
			create_request_issue(higher_level_review, end_product_establishment, "Active Duty Adjustments")
    end

    # 25 High Level Review, End Product Establishments that have a sync_status of cleared and are in_sync with
    # vbms_ext_claims
    25.times do
      veteran = create(:veteran, file_number: format("%<n>09d", n: @file_number))
      @file_number += 1
      # in_sync vbms_ext_claim LEVEL_STATUS_CODE "CLR"
			vbms_ext_claim = create_vbms_ext_claim(veteran, :cleared, :hlr)
			higher_level_review = create_high_level_review(veteran)
			end_product_establishment = create_end_product_establishment(higher_level_review,:cleared, vbms_ext_claim, veteran)

			create_request_issue(higher_level_review, end_product_establishment, "Military Retired Pay")
			create_request_issue(higher_level_review, end_product_establishment, "Active Duty Adjustments")
    end
    # # 25 Supplemental Claims, End Product Establishments that have a sync_status of cleared and are in_sync with
    # # vbms_ext_claims
    25.times do
      veteran = create(:veteran, file_number: format("%<n>09d", n: @file_number))
      @file_number += 1
      # in_sync vbms_ext_claim LEVEL_STATUS_CODE "CLR"
			vbms_ext_claim = create_vbms_ext_claim(veteran, :cleared, :slc)
			supplemental_claim = create_supplemental_claim(veteran)
			end_product_establishment = create_end_product_establishment(supplemental_claim, :cleared, vbms_ext_claim, veteran)

			create_request_issue(supplemental_claim, end_product_establishment, "Military Retired Pay")
			create_request_issue(supplemental_claim, end_product_establishment, "Active Duty Adjustments")
    end

    # # 25 Supplemental Claims, End Product Establishments that have a sync_status of canceled and are out_sync with
    # # vbms_ext_claims
    25.times do
      veteran = create(:veteran, file_number: format("%<n>09d", n: @file_number))
      @file_number += 1
      # in_sync vbms_ext_claim LEVEL_STATUS_CODE "CAN"
      vbms_ext_claim = create_vbms_ext_claim(veteran, :canceled, :slc)
			supplemental_claim = create_supplemental_claim(veteran)
			end_product_establishment = create_end_product_establishment(supplemental_claim, :canceled, vbms_ext_claim, veteran)

			create_request_issue(supplemental_claim, end_product_establishment, "Military Retired Pay")
			create_request_issue(supplemental_claim, end_product_establishment, "Active Duty Adjustments")
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


	def create_vbms_ext_claim(veteran, claim_status, claim)
		create(:vbms_ext_claim,
					 claim_status,
			     claim,
			     claimant_person_id: veteran.participant_id)
	end

	def create_high_level_review(veteran)
		create(:higher_level_review,
			     veteran_file_number: veteran.file_number)
	end

	def create_supplemental_claim(veteran)
		create(:supplemental_claim,
			     veteran_file_number: veteran.file_number,
					 receipt_date: Time.zone.now,
					 benefit_type: "compensation")
	end

	def create_end_product_establishment(source, claim_status, vbms_ext_claim, veteran)
		create(:end_product_establishment,
					 claim_status,
					 source: source,
				   reference_id: vbms_ext_claim.claim_id,
					 established_at: vbms_ext_claim.establishment_date,
					 claim_date: vbms_ext_claim.claim_date,
					 modifier: vbms_ext_claim.ep_code,
					 code: vbms_ext_claim.type_code,
					 veteran_file_number: veteran.file_number,
					 claimant_participant_id: veteran.participant_id)
	end

	def create_request_issue(decision_review, end_product_establishment, nonrating_issue_category)
		create(:request_issue,
					 decision_review: decision_review,
					 end_product_establishment: end_product_establishment,
					 nonrating_issue_category: nonrating_issue_category,
					 nonrating_issue_description: "nonrating description",
					 ineligible_reason: nil,
				 	 benefit_type: "compensation",
				 	 decision_date: Date.new(2018, 5, 1))
	end

 end
end
