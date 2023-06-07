# frozen_string_literal: true

# create vbms-ext-claim seeds
module Seeds

  class VbmsExtClaim < Base
    def seed!
      puts "******seed has been called******"
      # create_out_of_sync_epes_and_vbms_ext_claims
      # create_in_sync_epes_and_vbms_ext_claims
      create_vbms_ext_claims_with_no_end_product_establishment
    end

	 private

	# def create_out_of_sync_epes_and_vbms_ext_claims

	# end

	# def create_in_sync_epes_and_vbms_ext_claims

	# end

	def create_vbms_ext_claims_with_no_end_product_establishment
    100.times do
      create(:vbms_ext_claim)
    end
	end
 end
end
