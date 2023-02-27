=begin
End Products in VBMS get established (through the processing of End Product Establishments in Caseflow)
and if a duplicateEP error is caught it gets logged and prevents syncing with our external services when there
statuses were cancelled or cleared; we must perform a manual remediation script to handle these failed requests or a automation script.

This is the solution we've decided to impliment.

These remediation steps will upate the sync status manually or automatically for
"CAN" for cancelled, or "CLR" for "Cleared"
It also logs messages for the user.

This gets hit by when we run the WarRoom::DuppEpClaimsSyncStatusUpdateCanClr script in the Caseflow Rails console.

Usage: ./dupp-supp-claims-sync-status-update-can.sh <arg1> <arg2>
# ("Yes", "No") runs manual remediation
# ("No", "Yes") runs auto remediation

It is suspected that a expired BGS Attorney could cause this script to fail in which we would reach out to OAR for that correction and rerun the script if required.

In the manual script we check for proper vet file number first for data integrity (not included in the auto-script), in attempt to prevent any future issues,
we then cancel the sync status to clr or canceled. Cancel the intake of the clr or canceled appeal.

# Separation of concerns: The code is broken down into smaller,
more focused methods to improve readability and maintainability.

# Error handling: The code includes error handling for scenarios where the necessary data cannot be found.

# Logging: The code logs messages to help with debugging and audit trails.

# Encapsulation: The code utilizes encapsulation to control access to the various methods and properties of the objects being used.
=end

# frozen_string_literal: true

module WarRoom
  class DuppEpClaimsSyncStatusUpdateCanClr
    if
      def run(auto, sc_hlr)
        # set current user
        RequestStore[:current_user] = OpenStruct.new(ip_address: "127.0.0.1", station_id: "283", css_id: "CSFLOW", regional_office: "DSUSER")
        # Sets the variable End Product Establishment by the reference_id/Claim ID
        scs = SupplementalClaim.where("establishment_error ILIKE '%duplicateep%'")
        hlr = HigherLevelReview.where("establishment_error ILIKE '%duplicateep%'")
        # Grabs the problem scs with the status of Cancelled or Cleared
        problem_scs = scs.select { |sc|
          sc.veteran.end_products.select { |ep|
            ep.claim_type_code.include?("040") && ["CAN", "CLR"].include?(ep.status_type_code) &&
            [Date.today, 1.day.ago.to_date].include?(ep.last_action_date)
          }.empty?
        }
        problem_hlr = hlr.select { |hlr|
          hlr.end_products.select { |ep|
            ep.claim_type_code.include?("030") && ["CAN", "CLR"].include?(ep.status_type_code) &&
            [Date.today, 1.day.ago.to_date].include?(ep.last_action_date)
          }.empty?
        }
        # Count the total problem claims and keep track
        count = problem_scs.count + problem_hlr.count
        if count > 0
          Rails.logger.info("Found #{count} problem Supplemental Claims and/or Higher Level Reviews")
        else
          Rails.logger.info("No problem claims found. You can end your terminal session now.")
        end
        ActiveRecord::Base.transaction do
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
            # Reaches out to BGS services to create a new service for a claim
            bgs=BGSService.new.client.claims
            # Gather the claim details from bgs with it's async status.
            claim_detail = bgs.find_claim_detail_by_id(epe.reference_id)
            # Update the epe with the sync status as cancelled or cleared.
            if epe.claim_type_code == "040" && ["CAN", "CLR"].include?(epe.status_type_code) && [Date.today, 1.day.ago.to_date].include?(epe.last_action_date)
              if epe.status_type_code == "CAN"
                epe.update!(synced_status: "CAN", last_synced_at: Time.zone.now)
              else
                epe.update!(synced_status: "CLR", last_synced_at: Time.zone.now)
              end
            end
            # Cancel the original end product establishment
            epe.send(:cancel!)
            # Log a message for the user
            Rails.logger.info("Updated EPE for Supplemental Claim #{sc.id}")
          end
          hlr.each do |hlr|
            # Set the review to the first epe source appeal
            epe = hlr.end_product_establishment
            if epe.nil?
              Rails.logger.error("Unable to find EPE for Supplemental Claim #{hlr.id}. Skipping...")
              next
            end
            # stores the source of the of the EPE if HLR, Supplemental or AMA/Legacy Appeal.
            # If decision document set to the appeal of the source.
            source = (epe.source_type != "DecisionDocument") ? epe.source : epe.source.appeal
            if source.nil?
              Rails.logger.error("Could not find a source for the original EPE. Skipping Higher Level Review Claim #{hlr.id}...")
              next
            end
            claimant = source.claimant
            # Reaches out to BGS services to create a new service for a claim
            bgs=BGSService.new.client.claims
            # Gather the claim details from bgs with it's since status. This will show the sync status
            claim_detail = bgs.find_claim_detail_by_id(epe.reference_id)
            # Update the epe with the sync status as cancelled or cleared.
            if epe.claim_type_code == "030" && ["CAN", "CLR"].include?(epe.status_type_code) && [Date.today, 1.day.ago.to_date].include?(epe.last_action_date)
              if epe.status_type_code == "CAN"
                epe.update!(synced_status: "CAN", last_synced_at: Time.zone.now)
              else
                epe.update!(synced_status: "CLR", last_synced_at: Time.zone.now)
              end
            end
            # Cancel the original end product establishment
            epe.send(:cancel!)
            # Log a message for the user
            Rails.logger.info("Updated EPE for Higher Level Review Claim #{hlr.id}")
          end
        end
      end
    else
      logs == []
      if
        while
          def run(manual, sc_hlr)
            # set current user
            RequestStore[:current_user] = OpenStruct.new(ip_address: "127.0.0.1", station_id: "283", css_id: "CSFLOW", regional_office: "DSUSER")
            # Log a message for the user
            Rails.logger.info("You current user has been set to #{RequestStore[:current_user].css_id}")
            # Grabs the problem scs with the status of Cancelled or Cleared
            problem_scs = scs.select { |sc|
              sc.veteran.end_products.select { |ep|
                ep.claim_type_code.include?("040") && ["CAN", "CLR"].include?(ep.status_type_code) &&
                [Date.today, 1.day.ago.to_date].include?(ep.last_action_date)
              }.empty?
            }
            problem_hlr = hlr.select { |hlr|
              hlr.end_products.select { |ep|
                ep.claim_type_code.include?("030") && ["CAN", "CLR"].include?(ep.status_type_code) &&
                [Date.today, 1.day.ago.to_date].include?(ep.last_action_date)
              }.empty?
            }
            # Define the UUID regex pattern
            uuid_regex = /^\\h{8}-\\h{4}-\\h{4}-\\h{4}-\\h{12}$/
            # Count the total problem claims and keep track
            count = problem_scs.count + problem_hlr.count
            if count.zero?
              puts "No problem Supplemental Claims or Higher Level Reviews found. Exiting.\n"
              exit
            end
            puts "Found #{count} problem Supplemental Claims and Higher Level Reviews. Please enter the UUID of the first claim:\n"

            # This code finds the HigherLevelReviews or SupplementalClaims associated with the given UUID, then finds the SupplementalClaims and HigherLevelReviews
            # that contain the duplicateEP error.
            # It then filters these to only include the claims with establishment errors containing "duplicateep" for the individual SupplementalClaims or HigherLevelReviews ID
            # and joins them based on their associated EndProduct records. It then goes through and promts the user how he wants to manually handle the
            # problem duplicate ep claim.

            puts("We have checked for duplicate file records based upon your appeal and made necessary adjustments. It is now recommended to
              cancel the sink job of the appeal with the duplicateEP error. Please enter uuid of appeal to cancel the sink job for: \n")

            ActiveRecord::Base.transaction do
              uuid2 = gets.chomp.strip

              unless uuid2.match?(UUID_REGEX)
                raise "Invalid UUID format. Please enter a valid UUID.\n"
              end

              # Get SupplementalClaim or HigherLevelReview with a specific uuid
              sc = SupplementalClaim.find_by_uuid(uuid2)
              hlr = HigherLevelReview.find_by_uuid(uuid2)

              # Check if the uuid exists in either table
              unless sc || hlr
                puts "No SupplementalClaim or HigherLevelReview found with uuid: #{uuid2}\n"
                return
              end

              puts "Running match query for SC or HLRs that contain duplicateEP Errors\n"

              # This will check if both scs and hlr are nil, which means the provided UUID doesn't match any records
              # in the SupplementalClaim and HigherLevelReview tables with the establishment_error containing the "duplicateep" string.
              # If both are nil, it will print the "No uuid found for both SupplementalClaims and HigherLevelReviews"
              # message and return (or exit) the program.

              scs = SupplementalClaim.where("establishment_error ILIKE '%duplicateep%'").find_by(uuid: uuid2)
              hlr = HigherLevelReview.where("establishment_error ILIKE '%duplicateep%'").find_by(uuid: uuid2)

              if scs.nil? && hlr.nil?
                puts "No uuid found for both SupplementalClaims and HigherLevelReviews\n"
                return # or exit the program here, depending on your use case
              end

              duplicate_ep_problem_claim = nil

              # Query the SupplementalClaim table for a record with the specified uuid
              sc = SupplementalClaim.find_by(uuid: uuid2)
              if sc && sc.establishment_error.include?('duplicateep')
                # If a matching record was found and it has the establishment_error containing 'duplicateep',
                # then assign the result to the variable `problem_scs`
                problem_scs = sc
                puts "Putting data to be reviewed for SupplementalClaim ID #{sc.id}.\n"

                # Assign the `sc` object to `duplicate_ep_problem_claim`
                duplicate_ep_problem_claim = sc
              end

              # Query the HigherLevelReview table for a record with the specified uuid
              hlr = HigherLevelReview.find_by(uuid: uuid2)
              if hlr && hlr.establishment_error.include?('duplicateep')
                # If a matching record was found and it has the establishment_error containing 'duplicateep',
                # then assign the result to the variable `problem_hlr`
                problem_hlr = hlr
                puts "Putting data to be reviewed for HigherLevelReview ID #{hlr.id}.\n"

                # Assign the `hlr` object to `duplicate_ep_problem_claim`
                duplicate_ep_problem_claim = hlr
              end

              # Count the total problem claims and keep track
              count = duplicate_ep_problem_claim.count

              # If count is not 1, raise an error
              if count != 1
                raise "Duplicate EP problem claim count is off and manual remediation must be stopped\n"
              end

              # This code checks if duplicate_ep_problem_claim is not nil and if there are any matching
              # records in either the SupplementalClaim or HigherLevelReview table that have the same id as duplicate_ep_problem_claim.
              # If there are any matching records, it prints the message "Putting data to be reviewed for this hlr or sc id:"
              # followed by the id of the first matching record (if any), and if there are no matching records, it prints an error message and raises an interrupt.
              if (problem_scs = SupplementalClaim.where("establishment_error ILIKE '%duplicateep%'")
                .where(id: duplicate_ep_problem_claim&.id)).present? ||
               (problem_hlrs = HigherLevelReview.where("establishment_error ILIKE '%duplicateep%'")
                .where(id: duplicate_ep_problem_claim&.id)).present?
                puts "Putting data to be reviewed for this hlr or sc id: #{problem_scs&.id || problem_hlrs&.id}"
              else
                puts "The uuid provided does not match a problem claim with duplicateEP error\n"
                fail Interrupt
              end

              # Join the problem SupplementalClaims and HigherLevelReviews where duplicate_ep_problem_claim&.id.present? is true. Then displays data for user to decide upon.
              if duplicate_ep_problem_claim&.id.present?
                problem_claims = SupplementalClaim.joins(:end_products)
                  .where(end_products: { claim_type_code: "040", status_type_code: ["CAN", "CLR"], last_action_date: [Date.today, 1.day.ago.to_date] })
                  .where(id: duplicate_ep_problem_claim.id)
                  .merge(HigherLevelReview.joins(:end_products)
                    .where(end_products: { claim_type_code: "030", status_type_code: ["CAN", "CLR"], last_action_date: [Date.today, 1.day.ago.to_date] })
                    .where(id: duplicate_ep_problem_claim.id))
                puts "Found #{problem_claims.count} problem claim(s) for this duplicate EP problem. Here is the claim data"
                puts "The problem claim identified is listed here. #{problem_claims.first}.\n"

                # Set the review to the first epe source appeal
                epe = problem_claims.end_product_establishment
                if epe.nil?
                  Rails.logger.error("Unable to find EPE for Problem Claim #{epe.id}.")
                end

                puts "Providing end product establishment data, epe.id, for the epe in question or to be found #{epe.id}\n"

                # stores the source of the of the EPE if HLR, Supplemental or AMA/Legacy Appeal.
                # If decision document set to the appeal of the source.
                source = (epe.source_type != "DecisionDocument") ? epe.source : epe.source.appeal

                if source.nil?
                  Rails.logger.error("Could not find a source for the original EPE. #{epe.id}...\n")
                end

                puts "Source has been found here: #{source}\n"

                claimant = source.claimant

                if claimant.nil?
                  Rails.logger.error("Could not find a claimant for the source. #{source.id}...\n")
                end

                puts "Source Claimant has been found here: #{claimant}\n"

                # Reaches out to BGS services to create a new service for a claim
                bgs=BGSService.new.client.claims

                if bgs.nil?
                  Rails.logger.error("Could not perform BGSService.new.client.claims to display data")
                end

                puts "BGS service can be found: #{bgs}\n"

                # Gather the claim details from bgs with it's async status.
                claim_detail = bgs.find_claim_detail_by_id(epe.reference_id)

                if claim_detail.nil?
                  Rails.logger.error("Could not find the claim details from bgs with it's async status")
                end

                puts "Providing claim details for review, that should have sync status of cleared or cancel #{claim_detail}\n"

                count = duplicate_ep_problem_claim.count

                puts "duplicate_ep_problem_claim count: #{count}\n"
              else
                puts "No problem claims found for this duplicate EP problem\n"
              end
            end

            # Here we will use a begin get chomp method to perform the transaction on the SC or HLR data
            # Prompt user if he recogonizes change to the Appeal
            # and if he would like to manually up update the sync status by performing can or clr.
            # Prompt user to enter yes or no to fix the data manually by manually updating the caseflow sync status.
            # This will prompt the user yes or no to process the claim or recommended to save and close terminal to resart. Update the epe with the sync status as cancelled or cleared.
            if epe.claim_type_code == "040" && ["CAN", "CLR"].include?(epe.status_type_code) && [Date.today, 1.day.ago.to_date].include?(epe.last_action_date)
              puts "Please review the provided data. If you would like this claim data to be updated, enter 'yes' else enter 'no'.\n"
              input = gets.chomp.downcase
              while input != "yes" && input != "no"
                puts "Invalid input. Please enter 'yes' to update the claim data or 'no' to cancel.\n"
                input = gets.chomp.downcase
              end
              if input == "yes"
                if epe.status_type_code == "CAN"
                  epe.update!(synced_status: "CAN", last_synced_at: Time.zone.now)
                else
                  epe.update!(synced_status: "CLR", last_synced_at: Time.zone.now)
                end
              else
                puts "No updates were performed. Please close terminal and restart.\n"
              end
              puts "Updated epe synced status for #{epe.id}"
            end
            # Cancel the original end product establishment
            epe.send(:cancel!)
            puts "Canceled the original epe: #{epe.id}"
            # Log a message for the user
            puts "Claim data has been updated and the original end product establishment has been cancelled with a updated sync status.\n"
            # Reloads the epe
            epe.reload
            # Gather the claim details from bgs with it's new sync status.
            claim_detail = bgs.find_claim_detail_by_id(epe.reference_id)
            puts "Providing query results of new sync status here: #{claim_detail}\n"
            puts "You may now save data and exit the terminal\n"
          end
        end
      end
      logs.push"Manuel remediation script for #{uuid2} with #{claim_detail} completed\n"
      pp logs
    end
  end
end
