# frozen_string_literal: true

# VbmsExtClaim and related records are created here to test the new EP Establishment process
# To create the VbmsExtClaim table, run 'make external-db-create'
#
# To create the seeds, run 'make seed-vbms-ext-claim'
# => this can be ran multiple times to create more seeds
#
# To destroy the seeds and records related to EP Establishment testing, run 'make remove-vbms-ext-claim-seeds'
# => removes the audit tables; removes all PriorityEndProductSyncQueue, BatchProcess, and seed records; recreates audit tables
#
# To destroy the records mentioned above and re-seed, run 'make reseed-vbms-ext-claim'
module Seeds
  class VbmsExtClaim < Base

    def initialize
      file_number_initial_value
    end

    ################# records created ##################
    # 325 vbms_ext_claims (125 not connected to an EPE)
    # 200 veterans (each connected to an EPE)

    # 100 HLR EPEs
    # 50 out of sync with vbms
    # 25 "PEND", VEC "CLR" | 25 "CAN", VEC "CLR"
    #
    # 50 in sync with vbms =>
    # 25 "CAN", VEC "CAN" | 25 "CLR", VEC "CLR"

    # 100 SC EPEs
    # 50 out of sync with vbms =>
    # 25 "PEND", VEC "CAN" | 25 "CLR", VEC "CAN"
    #
    # 50 in sync with vbms =>
    # 25 "CLR", VEC "CLR" | 25 "CAN", VEC "CAN"

    # Each EPE has 2 request issues (one rating, one nonrating)
    # 400 request issues => 200 rating, 200 nonrating
    ####################################################
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
      # 25 High Level Review, End Product Establishments that have a sync_status of "PEND" and are out_of_sync with
      # vbms_ext_claims ("CLR")
      25.times do
        veteran = create(:veteran, file_number: format("%<n>09d", n: @file_number))
        @file_number += 1

        end_product_establishment = create_end_product_establishment(:active_hlr_with_cleared_vbms_ext_claim, veteran)
        request_issue1 = create_request_issue(:rating, end_product_establishment)
        request_issue2 = create_request_issue(:nonrating, end_product_establishment)
      end

      # 25 High Level Review, End Product Establishments that have a sync_status of "CAN" and are out_of_sync with
      # vbms_ext_claims ("CLR")
      25.times do
        veteran = create(:veteran, file_number: format("%<n>09d", n: @file_number))
        @file_number += 1

        end_product_establishment = create_end_product_establishment(:canceled_hlr_with_cleared_vbms_ext_claim, veteran)
        request_issue1 = create_request_issue(:rating, end_product_establishment)
        request_issue2 = create_request_issue(:nonrating, end_product_establishment)
      end

      # 25 Supplemental Claims, End Product Establishments that have a sync_status of "CLR" and are out_of_sync with
      # vbms_ext_claims ("CAN")
      25.times do
        veteran = create(:veteran, file_number: format("%<n>09d", n: @file_number))
        @file_number += 1

        end_product_establishment = create_end_product_establishment(:cleared_supp_with_canceled_vbms_ext_claim, veteran)
        request_issue1 = create_request_issue(:rating, end_product_establishment)
        request_issue2 = create_request_issue(:nonrating, end_product_establishment)
      end

      # 25 Supplemental Claims, End Product Establishments that have a sync_status of "PEND" and are out_of_sync with
      # vbms_ext_claims ("CAN")
      25.times do
        veteran = create(:veteran, file_number: format("%<n>09d", n: @file_number))
        @file_number += 1

        end_product_establishment = create_end_product_establishment(:active_supp_with_canceled_vbms_ext_claim, veteran)
        request_issue1 = create_request_issue(:rating, end_product_establishment)
        request_issue2 = create_request_issue(:nonrating, end_product_establishment)
      end
	  end

    ##
    # this in_sync method creates and seeds Vbms_Ext_Claims that have a Level_Status_Code matching the
    # End_Product_Establishment sync_status in order to test the sync_job and batch_job that finds differences between
    # VbmsExtClaim associated with the End Product Establishment. Both jobs should skip these objects because
    # Level_Status_Code matches the sync_status
    ##
    def create_in_sync_epes_and_vbms_ext_claims
      # 25 High Level Review, End Product Establishments that have a sync_status of "CAN" and are in_sync with
      # vbms_ext_claims ("CAN")
      25.times do
        veteran = create(:veteran, file_number: format("%<n>09d", n: @file_number))
        @file_number += 1

        end_product_establishment = create_end_product_establishment(:canceled_hlr_with_canceled_vbms_ext_claim, veteran)
        request_issue1 = create_request_issue(:rating, end_product_establishment)
        request_issue2 = create_request_issue(:nonrating, end_product_establishment)
      end

      # 25 High Level Review, End Product Establishments that have a sync_status of "CLR"" and are in_sync with
      # vbms_ext_claims ("CLR")
      25.times do
        veteran = create(:veteran, file_number: format("%<n>09d", n: @file_number))
        @file_number += 1

        end_product_establishment = create_end_product_establishment(:cleared_hlr_with_cleared_vbms_ext_claim, veteran)
        request_issue1 = create_request_issue(:rating, end_product_establishment)
        request_issue2 = create_request_issue(:nonrating, end_product_establishment)
      end

      # 25 Supplemental Claims, End Product Establishments that have a sync_status of "CLR" and are in_sync with
      # vbms_ext_claims ("CLR")
      25.times do
        veteran = create(:veteran, file_number: format("%<n>09d", n: @file_number))
        @file_number += 1

        end_product_establishment = create_end_product_establishment(:cleared_supp_with_cleared_vbms_ext_claim, veteran)
        request_issue1 = create_request_issue(:rating, end_product_establishment)
        request_issue2 = create_request_issue(:nonrating, end_product_establishment)
      end

      # 25 Supplemental Claims, End Product Establishments that have a sync_status of "CAN" and are in sync with
      # vbms_ext_claims ("CAN")
      25.times do
        veteran = create(:veteran, file_number: format("%<n>09d", n: @file_number))
        @file_number += 1

        end_product_establishment = create_end_product_establishment(:canceled_supp_with_canceled_vbms_ext_claim, veteran)
        request_issue1 = create_request_issue(:rating, end_product_establishment)
        request_issue2 = create_request_issue(:nonrating, end_product_establishment)
      end
    end

    ##
    # this method creates VBMS_EXT_CLAIMS that have yet to be Established in CASEFLOW to mimic
    # the VBMS API CALL. The VBMS_EXT_CLAIMS have no assocations to an End Product Establishment.
    ##
    def create_vbms_ext_claims_with_no_end_product_establishment
      # creates 50 non epe associated vbms_ext_claims with LEVEL_STATUS_CODE "CLR"
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

    # 'trait' will update the following EPE columns:
    # synced_status, established_at, modifier, code

    # additionally, the following records will be created:
    # an HLR or SC
    # a VbmsExtClaim
    def create_end_product_establishment(trait, veteran)
      create(:end_product_establishment, :canceled_hlr_with_cleared_vbms_ext_claim, veteran_file_number: veteran.file_number, claimant_participant_id: veteran.participant_id)
    end

    # 'trait' will specify if the RI is rating or nonrating

    # if it is rating, these columns will be updated:
    # contested_rating_issue_reference_id, contested_rating_issue_profile_date, decision_date

    # if it is nonrating, these columns will be updated:
    # nonrating_issue_category, decision_date, nonrating_issue_description
    def create_request_issue(trait, end_product_establishment)
      create(:request_issue,
              trait,
              decision_review: end_product_establishment.source,
              end_product_establishment: end_product_establishment
            )
    end

  end
end
