=begin
End Products in VBMS get established (through the processing of End Product Establishments in Caseflow)
and if a duplicateEP error is caught it gets logged and prevents syncing with our external services when there
statuses were cancelled or cleared.

Currently, there is no process to handle these request.

This code essentially creates a new end product establishment (EPE) to replace
the one that had the duplicate error, sets its synced status to "CAN" for cancelled,
establishes the new EPE, and cancels the old one. It also logs a message for the user.
This process is done for each supplemental claim that has the "duplicateep" error and
has an end product with a cleared status.

# This gets hit by when we run the WarRoom::DuppSuppClaimsSyncStatusUpdateCan job in the Caseflow Rails console.
# Usage: ./dupp-supp-claims-sync-status-update-can.sh <arg1> <arg2>
# where <arg1> is the first argument to pass to the job and <arg2> is the second argument.
=end

# frozen_string_literal: true

module WarRoom
    class DuppSuppClaimsSyncStatusUpdateClr
      def run(dupp_supp_claims_sync_status_update_clr, update_sync_clr)
        # set current user
        RequestStore[:current_user] = OpenStruct.new(ip_address: "127.0.0.1", station_id: "283", css_id: "CSFLOW", regional_office: "DSUSER")

        # Sets the variable End Product Establishment by the reference_id/Claim ID
        scs = SupplementalClaim.where("establishment_error ILIKE '%duplicateep%'")

        problem_scs = scs.select { |sc|
          sc.veteran.end_products.select { |ep|
            ep.claim_type_code.include?("040") && ["CLR"].include?(ep.status_type_code) &&
            [Date.today, 1.day.ago.to_date].include?(ep.last_action_date)
          }.empty?
        }

        # Count the total problem claims and keep track
        count = scs.count
        Rails.logger.info("Found #{count} problem Supplemental Claims.")

        scs.each do |sc|
          # Set the review to the first epe source appeal
          epe = sc.end_product_establishment

          if epe.nil?
            Rails.logger.error("Unable to find EPE for Supplemental Claim #{sc.id}. Skipping...")
            next
          end

          # stores the source of the of the EPE if HLR, Supplemental or AMA/Legacy Appeal.
          # If decision document set to the appeal of the source.
          source = (epe.source_type != "DecisionDocument") ? epe.source : epe.source.appeal

          if source.nil?
            Rails.logger.error("Could not find a source for the original EPE. Skipping Supplemental Claim #{sc.id}...")
            next
          end

          claimant = source.claimant

          # Re-establish new end product with the correct payee code and origin EPE source information.
          new_epe = establish_new_endproduct_establishment(epe, claimant)

          if ["030BGR", "030BGRNR", "030BGRPMC", "030BGNRPMC"].include?(epe.code)
            # If it's a Board Grant EPE (030BGR, 030BGRNR, 030BGRPMC, 030BGNRPMC)
            # We want to connect the newly created End Product Establishment to the
            # corresponding Board Grant Effectuation on the old EPE.
            epe.source.effectuations.update_all(end_product_establishment_id: new_epe.id, contention_reference_id: nil)
          else
            # All other forms of EPEs, you will connect it to the Request Issues on the old EPE.
            epe.source.request_issues.update_all(end_product_establishment_id: new_epe.id, contention_reference_id: nil, closed_status: nil, closed_at: nil)
          end

          # Establishes the new EP
          new_epe.establish!

          # Cancels the original EP
          epe.send(:cancel!)

          # Log a message for the user
          Rails.logger.info("Updated EPE for Supplemental Claim #{sc.id}")
        end
      end

      private
      def establish_new_endproduct_establishment(epe, claimant)
        EndProductEstablishment.create(
          source_type: epe.source_type,
          source_id: epe.source_id,
          veteran_file_number: epe.veteran_file_number,
          claim_date: epe.claim_date,
          code: epe.code,
          station: epe.station,
          claimant_participant_id: !claimant.nil? ? claimant.participant_id : epe.claimant_participant_id,
          payee_code: correct_payee_code,
          doc_reference_id: epe.doc_reference_id,
          synced_status: "CLR",
          last_synced_at: Time.zone.now
        ).tap do |epe2|
          # Set the new end product establishment as established
          epe2.establish!

          # Cancel the original end product establishment
          epe.send(:cancel!)

          # Log a message for the user
          Rails.logger.info("Updated EPE for Supplemental Claim #{epe.source_id}")
        end
    end
end
