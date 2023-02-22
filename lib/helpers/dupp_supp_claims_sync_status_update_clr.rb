=begin
End Products in VBMS get established (through the processing of End Product Establishments in Caseflow)
and if a duplicateEP error is caught it gets logged and prevents syncing with our external services when there
statuses were cancelled or cleared; we must perform a manual remediation script to handle these failed requests.

This is the solution we've decided to impliment.

These remediation steps will upate the sync status manually or automatically for
 "CAN" for cancelled, or "CLR" for "Cleared"
It also logs messages for the user.

This gets hit by when we run the WarRoom::DuppSuppClaimsSyncStatusUpdateCan job in the Caseflow Rails console.

Usage: ./dupp-supp-claims-sync-status-update-can.sh <arg1> <arg2>
where <arg1> is the first argument to pass to the job and <arg2> is the second argument.

It is suspected that a expired BGS Attorney could cause this script to fail in which we would reach out to OAR and rerun the script.

# Separation of concerns: The code is broken down into smaller,
more focused methods to improve readability and maintainability.

# Error handling: The code includes error handling for scenarios where the necessary data cannot be found.

# Logging: The code logs messages to help with debugging and audit trails.

# Encapsulation: The code utilizes encapsulation to control access to the various methods and properties of the objects being used.
=end

# frozen_string_literal: true

module WarRoom
  class DuppSuppClaimsSyncStatusUpdateClr
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

      if
        def run(manual, type)
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
            puts "No problem Supplemental Claims or Higher Level Reviews found. Exiting."
            exit
          end
          puts "Found #{count} problem Supplemental Claims and Higher Level Reviews. Please enter the UUID of the first claim:"
          # Prompt the user to enter a UUID and catch any errors
          begin
            uuid = gets.chomp.strip
            unless uuid.match?(UUID_REGEX)
              raise "Invalid UUID format. Please enter a valid UUID. This does not match our required pattern"
            end
          rescue => e
            puts e.message
            retry
          end
          # Find the appeal with the given UUID
          appeal = Appeal.find_by_uuid(uuid)
          if appeal.nil?
            puts "Appeal with UUID #{uuid} not found."
            exit
          end
          # Next for lines of code in the commands; we will want to query the Dupplicate EP Dashboard to see if that UUID shows up
          # If it shows up. We want to pp all data.
          # Prompt user to enter yes or no to fix the data manually by manually updating the caseflow sync status.
          # If no appeal is found in the table. Prompt the user that the appeal UUID is invalid as no duplicate EP error exists for that appeal.
          # Perform the validation check on Appeal
          # PP Appeal Data
          # Prompt user if he recogonizes change to the Appeal and if he would like to manually up update the sync status by performing.
        end
      end
    end
  end
end
