# End Products in VBMS get established (through the processing of End Product Establishments in Caseflow)
# and if a duplicateEP error is caught it gets logged and prevents syncing with our external services when there
# statuses were cancelled or cleared; we must perform a manual remediation script to handle these failed requests or a automation script.

# This is the solution we've decided to impliment.

# These remediation steps will upate the sync status manually or automatically for
# "CAN" for cancelled, or "CLR" for "Cleared"
# It also logs messages for the user.

# This gets hit by when we run the WarRoom::DuppEpClaimsSyncStatusUpdateCanClr script in the Caseflow Rails console.

# Usage: ./dupp-ep-claims-sync-status-update-can-clr.sh <arg1> <arg2>
# (manual, sc_hlr) runs manual remediation
# (auto, sc_hlr) runs auto remediation

# It is suspected that a expired BGS Attorney could cause this script to fail in which we would reach out to OAR for that correction and rerun the script if required.

# In the manual script we check for proper vet file number first for data integrity (not included in the auto-script), in attempt to prevent any future issues,
# we then cancel the sync status to clr or canceled. Cancel the intake of the clr or canceled appeal.

# Separation of concerns: The code is broken down into smaller,
# more focused methods to improve readability and maintainability.

# Error handling: The code includes error handling for scenarios where the necessary data cannot be found.

# Logging: The code logs messages to help with debugging and audit trails.

# Encapsulation: The code utilizes encapsulation to control access to the various methods and properties of the objects being used.

# frozen_string_literal: true

module WarRoom
  class DuppEpClaimsSyncStatusUpdateCanClr
      def run(manual, sc_hlr)
        scs = SupplementalClaim.where("establishment_error ILIKE '%duplicateep%'")
        hlr = HigherLevelReview.where("establishment_error ILIKE '%duplicateep%'")
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
          hlr.veteran.end_products.select { |ep|
            ep.claim_type_code.include?("030") && ["CAN", "CLR"].include?(ep.status_type_code) &&
            [Date.today, 1.day.ago.to_date].include?(ep.last_action_date)
          }.empty?
        }
        # Count the total problem claims and keep track
        count = problem_scs.count + problem_hlr.count
        if count.zero?
          puts "No problem Supplemental Claims or Higher Level Reviews found. Exiting.\n"
          fail interrupt
        end
        puts "Found #{count} problem Supplemental Claims and Higher Level Reviews. Please enter the UUID of the first claim:\n"

        # This code finds the SupplementalClaims and HigherLevelReviews
        # that contain the duplicateEP error with the provided UUID.
        # It then filters these to only include the claims with establishment errors containing "duplicateep" for the individual SupplementalClaims or HigherLevelReviews ID
        # and joins them based on their associated EndProduct records. It then goes through and promts the user how he wants to manually handle the
        # problem duplicate ep claim.
        ActiveRecord::Base.transaction do
          uuid2 = gets.chomp.strip

          # This will check if both scs and hlr are nil, which means the provided UUID doesn't match any records
          # in the SupplementalClaim and HigherLevelReview tables with the establishment_error containing the "duplicateep" string.

          puts "Running match query for SC or HLR that contain duplicateEP Errors for uuid: #{uuid2}\n"

          def problem_claim(uuid2)
            # Query the SupplementalClaim table for a record with the specified uuid and establishment_error containing 'duplicateep'
            sc = SupplementalClaim.where("establishment_error ILIKE '%duplicateep%'").find_by(uuid: uuid2)

            # Query the HigherLevelReview table for a record with the specified uuid and establishment_error containing 'duplicateep'
            hlr = HigherLevelReview.where("establishment_error ILIKE '%duplicateep%'").find_by(uuid: uuid2)

            # Check if either sc or hlr is not nil, but not both
            if sc.nil? && hlr.nil?
              puts "No SupplementalClaim or HigherLevelReview found with uuid: #{uuid2}\n"
              return duplicate_ep_problem_claim = nil
              fail interupt
            elsif !sc.nil? && hlr.nil?
              problem_claim = sc
              puts "Putting data to be reviewed for SupplementalClaim ID #{sc.id}.\n"
            elsif sc.nil? && !hlr.nil?
              problem_claim = hlr
              puts "Putting data to be reviewed for HigherLevelReview ID #{hlr.id}.\n"
            else
              puts "Error: Multiple records found with the same UUID and establishment_error containing 'duplicateep'\n"
              return duplicate_ep_problem_claim = nil
              fail interupt
            end

            # Assign the `problem_claim` object to `duplicate_ep_problem_claim`
            duplicate_ep_problem_claim = problem_claim

            # If duplicate_ep_problem_claim is nil, raise an error
            if duplicate_ep_problem_claim.nil?
              raise "Duplicate EP problem claim count is off and manual remediation must be stopped\n"
              fail interupt
            end

            puts "#{duplicate_ep_problem_claim} : the duplicate_ep_problem_claim has been identified, displaying the claim data"

            # Set the review to the first epe source appeal
            epe = duplicate_ep_problem_claim.veteran.end_product_establishment

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

          puts "Please review the provided data. If you would like this claim data to be updated, enter 'yes' else enter 'no'.\n"

          # Here we will use a begin get chomp method to perform the transaction on the SC or HLR data
          # Prompt user if he recogonizes change to the Appeal
          # and if he would like to manually, update the sync status by performing can or clr.
          # Prompt user to enter yes or no to fix the data manually by updating the caseflow sync status.
          # This will prompt the user yes or no to process the claim or recommended to save and close terminal to resart. Update the epe with the sync status as cancelled or cleared.
          ActiveRecord::Base.transaction do
            if epe.claim_type_code == "040" && ["CAN", "CLR"].include?(epe.status_type_code) && [Date.today, 1.day.ago.to_date].include?(epe.last_action_date)

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
                fail interupt
              end

              puts "Updated epe synced status for #{epe.id}"
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

              # Until end, the next few lines of code reruns the query count and displays the total problem count; which should've been reduced by one
              # If Remediation was successful

              scs = SupplementalClaim.where("establishment_error ILIKE '%duplicateep%'")
              hlr = HigherLevelReview.where("establishment_error ILIKE '%duplicateep%'")

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
                hlr.veteran.end_products.select { |ep|
                  ep.claim_type_code.include?("030") && ["CAN", "CLR"].include?(ep.status_type_code) &&
                  [Date.today, 1.day.ago.to_date].include?(ep.last_action_date)
                }.empty?
              }

              # Count the total problem claims and keep track

              count = problem_scs.count + problem_hlr.count

              if count.zero?
                puts "No problem Supplemental Claims or Higher Level Reviews found. Exiting.\n"
              end

              puts "Found #{count} problem Supplemental Claims and Higher Level Reviews. This should be one less from your original count"

              puts "You may now save data and exit the terminal\n"
            end
          end
        end
      end

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
          hlr.veteran.end_products.select { |ep|
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
        Rails.logger.info("Beginning to Auto Cancel Problem Claims.")
        problem_scs.each do |sc|
          # Set the review to the first epe source appeal
          epe = problem_scs.first.veteran.end_products
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
        problem_hlr.each do |hlr|
          # Set the review to the first epe source appeal
          epe = problem_hlr.first.veteran.end_products
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
        # Until End, next few lines perform the count and display the count completion.
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
          hlr.veteran.end_products.select { |ep|
            ep.claim_type_code.include?("030") && ["CAN", "CLR"].include?(ep.status_type_code) &&
            [Date.today, 1.day.ago.to_date].include?(ep.last_action_date)
          }.empty?
        }
        # Count the total problem claims and keep track
        count = problem_scs.count + problem_hlr.count
        Rails.logger.info("Found #{count} problem Supplemental Claims and/or Higher Level Reviews")
      end
    end
  end
end
