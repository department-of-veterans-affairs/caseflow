# frozen_string_literal: true

# create vbms-ext-claim seeds
module Seeds

  class VbmsExtClaim < Base
    def seed!
      puts "******seed has been called******"
      create_vbms_ext_claims_with_no_end_product_establishment
      create_in_sync_epes_and_vbms_ext_claims
      # create_out_of_sync_epes_and_vbms_ext_claims
    end

	 private

	# def create_out_of_sync_epes_and_vbms_ext_claims

	# end

	def create_in_sync_epes_and_vbms_ext_claims

    # 25 High Level Review, End Product Establishments that have a sync_status of cleared and are in_sync with
    # vbms_ext_claims
    25.times do |n|
      veteran = create(:veteran)
      epe =  create(:end_product_establishment, :cleared, reference_id: 200_00 + n, veteran_file_number: veteran.file_number)
      higher_level_review = create(
        :higher_level_review,
        end_product_establishments: [epe],
        veteran_file_number: veteran.file_number
      )
      # vbms_ext_claim LEVEL_STATUS_CODE "CLR"
      create(:vbms_ext_claim, :cleared, claim_id: epe.reference_id )
    end
    # 25 High Level Review, End Product Establishments that have a sync_status of canceled and are in_sync with
    # vbms_ext_claims
    25.times do |n|
      veteran = create(:veteran)
      epe =  create(:end_product_establishment, :canceled, reference_id: 300_00 + n, veteran_file_number: veteran.file_number)
      higher_level_review = create(
        :higher_level_review,
        end_product_establishments: [epe],
        veteran_file_number: veteran.file_number
      )
      # vbms_ext_claim LEVEL_STATUS_CODE "CAN"
      create(:vbms_ext_claim, :canceled, claim_id: epe.reference_id )
    end

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
