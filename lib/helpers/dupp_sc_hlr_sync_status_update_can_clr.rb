=begin
End Products in VBMS get established (through the processing of End Product Establishments in Caseflow)
and if a duplicateEP error is caught it gets logged and prevents syncing with our external services when there
statuses were cancelled or cleared; we must perform a manual remediation script to handle these failed requests or a automation script.

This is the solution we've decided to impliment.

These remediation steps will upate the sync status manually or automatically for
"CAN" for cancelled, or "CLR" for "Cleared"
It also logs messages for the user.

This gets hit by when we run the WarRoom::DuppSuppClaimsSyncStatusUpdateCanClr script in the Caseflow Rails console.

Usage: ./dupp-supp-claims-sync-status-update-can.sh <arg1> <arg2>
# "yes no" runs manual remediation
# "no yes" runs auto remediation

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
  class DuppScHlrSyncStatusUpdateCanClr
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
      if
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
          # Prompt the user to enter a UUID and catch any errors
          begin
            uuid = gets.chomp.strip
            unless uuid.match?(UUID_REGEX)
              raise "Invalid UUID format. Please enter a valid UUID. This does not match our required pattern"
            end
            check_by_ama_appeal_uuid(uuid)
          rescue => e
            puts "#{e.message}\n"
            retry
          end

          # Find the appeal with the given UUID
          def check_by_ama_appeal_uuid(uuid)
            a = Appeal.find_by_uuid(uuid)

            if a.nil?
              puts("Appeal was not found. Aborting\n")
              fail Interrupt
            elsif a.veteran.nil?
              puts("veteran is not assiciated to this appeal. Aborting...\n")
              fail Interrupt
            elsif a.veteran.file_number.empty?
              puts("Veteran tied to appeal does not have a file_number. Aborting..\n")
              fail Interrupt
            end

            check_by_duplicate_veteran_file_number(a.veteran.file_number)
          end

          def run_remediation_by_ama_appeal_uuid(appeal_uuid)
            a = Appeal.find_by_uuid(appeal_uuid)

            if a.nil?
              puts("Appeal was not found. Aborting\n")
              fail Interrupt
            elsif a.veteran.nil?
              puts("veteran is not assiciated to this appeal. Aborting...\n")
              fail Interrupt
            elsif a.veteran.file_number.empty?
              puts("Veteran tied to appeal does not have a file_number. Aborting..\n")
              fail Interrupt
            end

            run_remediation(a.veteran.file_number)
          end

          def check_by_duplicate_veteran_file_number(duplicate_veteran_file_number)
            # check if only one vet has the old file number
            vets = Veteran.where(file_number: duplicate_veteran_file_number)

            # Check that only one vet has the bad file number
            if vets.nil? || vets.count > 1
              puts("More than on vet with the duplicate veteran file number exists. Aborting..\n")
              fail Interrupt
            end

            # Get the duplicate veteran into memory
            v = Veteran.find_by_file_number(duplicate_veteran_file_number)

            # Set variable to hold old file_number (file number on duplicate veteran)
            old_file_number = v.file_number

            # Check if veteran is not found
            if v.nil?
              puts("No veteran found. Aborting.\n")
              fail Interrupt
            end

            # Check if there in fact duplicate veterans. Can be duplicated with
            # same partipant id or ssn
            dupe_vets = Veteran.where("ssn = ? or participant_id = ?", v.ssn, v.participant_id)

            v2 = nil

            vet_ssn = v.ssn
            # checks if we get no vets or less than 2 vets}
            if dupe_vets.nil? || dupe_vets.count < 2
              puts("No duplicate veteran found\n")
              fail Interrupt
            elsif dupe_vets.count > 2 # check if we get more than 2 vets back
              puts("More than two veterans found. Aborting\n")
              fail Interrupt
            else
              other_v = dupe_vets.first # grab first of the dupilicates and check if the duplicate veteran}
              if other_v.file_number == old_file_number
                other_v = dupe_vets.last # First is duplicate veteran so get 2nd
              end
              if other_v.file_number.empty? || other_v.file_number == old_file_number #if correct veteran has wrong file number
                puts("Both veterans have the same file_number or No file_number on the correct veteran. Aborting...\n")
                fail Interrupt
              elsif v.ssn.empty? && !other_v.ssn.empty?
                vet_ssn = other_v.ssn
              elsif v.ssn.empty? && other_v.ssn.empty?
                puts("Neither veteran has a ssn and a ssn is needed to check the BGS file number. Aborting\n")
                fail Interrupt
              elsif !other_v.ssn.empty? && v.ssn != other_v.ssn
                puts("Veterans do not have the same ssn and a correct ssn needs to be chosen. Aborting.\n")
                fail Interrupt
              else
                vet_ssn = v.ssn
              end
              v2 = other_v
            end

            duplicate_relations = ""

            # Get the correct file number from a BGS call out
            file_number = BGSService.new.fetch_file_number_by_ssn(vet_ssn)

            if file_number != v2.file_number
              puts("File number from BGS does not match correct veteran record. Aborting...\n")
              fail Interrupt
            end

            # The following code runs through all possible relations
            # to the duplicat veteran by file number or veteran id
            # collects all counts and displays all relations
            as = Appeal.where(veteran_file_number: old_file_number)

            as_count = as.count

            duplicate_relations += as_count.to_s + " Appeals\n"

            las = LegacyAppeal.where(vbms_id: convert_file_number_to_legacy(old_file_number))

            las_count = las.count

            duplicate_relations += las_count.to_s + " LegacyAppeals\n"

            ahls = AvailableHearingLocations.where(veteran_file_number: old_file_number)

            ahls_count = ahls.count

            duplicate_relations += ahls_count.to_s + " Avialable Hearing Locations\n"

            bpoas = BgsPowerOfAttorney.where(file_number: old_file_number)

            bpoas_count = bpoas.count

            duplicate_relations += bpoas_count.to_s + " BgsPowerOfAAttorneys\n"

            ds = Document.where(file_number: old_file_number)

            ds_count = ds.count

            duplicate_relations += ds_count.to_s + " Documents\n"

            epes = EndProductEstablishment.where(veteran_file_number: old_file_number)

            epes_count = epes.count

            duplicate_relations += epes_count.to_s + " EndProductEstablishment\n"

            f8s = Form8.where(file_number: convert_file_number_to_legacy(old_file_number))

            f8s_count = f8s.count

            duplicate_relations += f8s_count.to_s + " Form8\n"

            hlrs = HigherLevelReview.where(veteran_file_number: old_file_number)

            hlrs_count = hlrs.count

            duplicate_relations += hlrs_count.to_s + " HigherLevelReview\n"

            is_fn = Intake.where(veteran_file_number: old_file_number)

            is_fn_count = is_fn.count

            duplicate_relations += is_fn_count.to_s + " Intakes related by file number\n"

            is_vi = Intake.where(veteran_id: v.id)

            is_vi_count = is_vi.count

            duplicate_relations += is_vi_count.to_s + " Intakes related by veteran id\n"

            res = RampElection.where(veteran_file_number: old_file_number)

            res_count = res.count

            duplicate_relations += res_count.to_s + " RampElection\n"

            rrs = RampRefiling.where(veteran_file_number: old_file_number)

            rrs_count = rrs.count

            duplicate_relations += rrs_count.to_s + " RampRefiling\n"

            scs = SupplementalClaim.where(veteran_file_number: old_file_number)

            scs_count = scs.count

            duplicate_relations += scs_count.to_s + " SupplementalClaim\n"

            puts("Duplicate Veteran Relations:\n" + duplicate_relations)

            # Get relationship list for correct veteran

            correct_relations = ""

            as2 = Appeal.where(veteran_file_number: file_number)

            as2_count = as2.count

            correct_relations += as2_count.to_s + " Appeals\n"

            las2 = LegacyAppeal.where(vbms_id: convert_file_number_to_legacy(file_number))

            las2_count = las2.count

            correct_relations += las2_count.to_s + " LegacyAppeals\n"

            ahls2 = AvailableHearingLocations.where(veteran_file_number: file_number)

            ahls2_count = ahls2.count

            correct_relations += ahls2_count.to_s + " Avialable Hearing Locations\n"

            bpoas2 = BgsPowerOfAttorney.where(file_number: file_number)

            bpoas2_count = bpoas2.count

            correct_relations += bpoas2_count.to_s + " BgsPowerOfAAttorneys\n"

            ds2 = Document.where(file_number: file_number)

            ds2_count = ds2.count

            correct_relations += ds2_count.to_s + " Documents\n"

            epes2 = EndProductEstablishment.where(veteran_file_number: file_number)

            epes2_count = epes2.count

            correct_relations += epes2_count.to_s + " EndProductEstablishment\n"

            f8s2 = Form8.where(file_number: convert_file_number_to_legacy(file_number))

            f8s2_count = f8s2.count

            correct_relations += f8s2_count.to_s + " Form8\n"

            hlrs2 = HigherLevelReview.where(veteran_file_number: file_number)

            hlrs2_count = hlrs2.count

            correct_relations += hlrs2_count.to_s + " HigherLevelReview\n"

            is_fn2 = Intake.where(veteran_file_number: file_number)

            is_fn2_count = is_fn2.count

            correct_relations += is_fn2_count.to_s + " Intakes related by file number\n"

            is_vi2 = Intake.where(veteran_id: v.id)

            is_vi2_count = is_vi2.count

            correct_relations += is_vi2_count.to_s + " Intakes related by veteran id\n"

            res2 = RampElection.where(veteran_file_number: file_number)

            res2_count = res2.count

            correct_relations += res2_count.to_s + " RampElection\n"

            rrs2 = RampRefiling.where(veteran_file_number: file_number)

            rrs2_count = rrs2.count

            correct_relations += rrs2_count.to_s + " RampRefiling\n"

            scs2 = SupplementalClaim.where(veteran_file_number: file_number)

            scs2_count = scs2.count

            correct_relations += scs2_count.to_s + " SupplementalClaim\n"

            puts("Correct Veteran Relations:\n" + correct_relations)
          end

          def run_remediation(duplicate_veteran_file_number)
            # check if only one vet has the old file number
            vets = Veteran.where(file_number: duplicate_veteran_file_number)

            # Check that only oen vet has the bad file number
            if vets.nil? || vets.count > 1
              puts("More than on vet with the duplicate veteran file number exists. Aborting..\n")
              fail Interrupt
            end

            # Get the duplicate veteran into memory
            v = Veteran.find_by_file_number(duplicate_veteran_file_number)

            # Set variable to hold old file_number (file number on duplicate veteran)
            old_file_number = v.file_number

            # Check if veteran is not found
            if v.nil?
              puts("No veteran found. Aborting.\n")
              fail Interrupt
            end

            # Check if there in fact duplicate veterans. Can be duplicated with
            # same partipant id or ssn
            dupe_vets = Veteran.where("ssn = ? or participant_id = ?", v.ssn, v.participant_id)

            v2 = nil

            vet_ssn = v.ssn
            # checks if we get no vets or les sthan 2 vets}
            if dupe_vets.nil? || dupe_vets.count < 2
              puts("No duplicate veteran found\n")
              fail Interrupt
            elsif dupe_vets.count > 2 # check if we get more than 2 vets back
              puts("More than two veterans found. Aborting\n")
              fail Interrupt
            else
              other_v = dupe_vets.first # grab first of the dupilicates and check if the duplicate veteran}
              if other_v.file_number == old_file_number
                other_v = dupe_vets.last # First is duplicate veteran so get 2nd
              end
              if other_v.file_number.empty? || other_v.file_number == old_file_number #if correct veteran has wrong file number
                puts("Both veterans have the same file_number or No file_number on the correct veteran. Aborting...\n")
                fail Interrupt
              elsif v.ssn.empty? && !other_v.ssn.empty?
                vet_ssn = other_v.ssn
              elsif v.ssn.empty? && other_v.ssn.empty?
                puts("Neither veteran has a ssn and a ssn is needed to check the BGS file number. Aborting\n")
                fail Interrupt
              elsif !other_v.ssn.empty? && v.ssn != other_v.ssn
                puts("Veterans do not have the same ssn and a correct ssn needs to be chosen. Aborting.\n")
                fail Interrupt
              else
                vet_ssn = v.ssn
              end
              v2 = other_v
            end

            duplicate_relations = ""

            # Get the correct file number from a BGS call out
            file_number = BGSService.new.fetch_file_number_by_ssn(vet_ssn)

            if file_number != v2.file_number
              puts("File number from BGS does not match correct veteran record. Aborting...\n")
              fail Interrupt
            end

            # The following code runs through all possible relations
            # to the duplicat evetran by file number or veteran id
            # collects all counts and displays all relations
            as = Appeal.where(veteran_file_number: old_file_number)

            as_count = as.count

            duplicate_relations += as_count.to_s + " Appeals\n"

            las = LegacyAppeal.where(vbms_id: convert_file_number_to_legacy(old_file_number))

            las_count = las.count

            duplicate_relations += las_count.to_s + " LegacyAppeals\n"

            ahls = AvailableHearingLocations.where(veteran_file_number: old_file_number)

            ahls_count = ahls.count

            duplicate_relations += ahls_count.to_s + " Avialable Hearing Locations\n"

            bpoas = BgsPowerOfAttorney.where(file_number: old_file_number)

            bpoas_count = bpoas.count

            duplicate_relations += bpoas_count.to_s + " BgsPowerOfAAttorneys\n"

            ds = Document.where(file_number: old_file_number)

            ds_count = ds.count

            duplicate_relations += ds_count.to_s + " Documents\n"

            epes = EndProductEstablishment.where(veteran_file_number: old_file_number)

            epes_count = epes.count

            duplicate_relations += epes_count.to_s + " EndProductEstablishment\n"

            f8s = Form8.where(file_number: convert_file_number_to_legacy(old_file_number))

            f8s_count = f8s.count

            duplicate_relations += f8s_count.to_s + " Form8\n"

            hlrs = HigherLevelReview.where(veteran_file_number: old_file_number)

            hlrs_count = hlrs.count

            duplicate_relations += hlrs_count.to_s + " HigherLevelReview\n"

            is_fn = Intake.where(veteran_file_number: old_file_number)

            is_fn_count = is_fn.count

            duplicate_relations += is_fn_count.to_s + " Intakes related by file number\n"

            is_vi = Intake.where(veteran_id: v.id)

            is_vi_count = is_vi.count

            duplicate_relations += is_vi_count.to_s + " Intakes related by veteran id\n"

            res = RampElection.where(veteran_file_number: old_file_number)

            res_count = res.count

            duplicate_relations += res_count.to_s + " RampElection\n"

            rrs = RampRefiling.where(veteran_file_number: old_file_number)

            rrs_count = rrs.count

            duplicate_relations += rrs_count.to_s + " RampRefiling\n"

            scs = SupplementalClaim.where(veteran_file_number: old_file_number)

            scs_count = scs.count

            duplicate_relations += scs_count.to_s + " SupplementalClaim\n"

            puts("Duplicate Veteran Relations:\n" + duplicate_relations)

            # Get relationship list for correct veteran

            correct_relations = ""

            as2 = Appeal.where(veteran_file_number: file_number)

            as2_count = as2.count

            correct_relations += as2_count.to_s + " Appeals\n"

            las2 = LegacyAppeal.where(vbms_id: convert_file_number_to_legacy(file_number))

            las2_count = las2.count

            correct_relations += las2_count.to_s + " LegacyAppeals\n"

            ahls2 = AvailableHearingLocations.where(veteran_file_number: file_number)

            ahls2_count = ahls2.count

            correct_relations += ahls2_count.to_s + " Avialable Hearing Locations\n"

            bpoas2 = BgsPowerOfAttorney.where(file_number: file_number)

            bpoas2_count = bpoas2.count

            correct_relations += bpoas2_count.to_s + " BgsPowerOfAAttorneys\n"

            ds2 = Document.where(file_number: file_number)

            ds2_count = ds2.count

            correct_relations += ds2_count.to_s + " Documents\n"

            epes2 = EndProductEstablishment.where(veteran_file_number: file_number)

            epes2_count = epes2.count

            correct_relations += epes2_count.to_s + " EndProductEstablishment\n"

            f8s2 = Form8.where(file_number: convert_file_number_to_legacy(file_number))

            f8s2_count = f8s2.count

            correct_relations += f8s2_count.to_s + " Form8\n"

            hlrs2 = HigherLevelReview.where(veteran_file_number: file_number)

            hlrs2_count = hlrs2.count

            correct_relations += hlrs2_count.to_s + " HigherLevelReview\n"

            is_fn2 = Intake.where(veteran_file_number: file_number)

            is_fn2_count = is_fn2.count

            correct_relations += is_fn2_count.to_s + " Intakes related by file number\n"

            is_vi2 = Intake.where(veteran_id: v.id)

            is_vi2_count = is_vi2.count

            correct_relations += is_vi2_count.to_s + " Intakes related by veteran id\n"

            res2 = RampElection.where(veteran_file_number: file_number)

            res2_count = res2.count

            correct_relations += res2_count.to_s + " RampElection\n"

            rrs2 = RampRefiling.where(veteran_file_number: file_number)

            rrs2_count = rrs2.count

            correct_relations += rrs2_count.to_s + " RampRefiling\n"

            scs2 = SupplementalClaim.where(veteran_file_number: file_number)

            scs2_count = scs2.count

            correct_relations += scs2_count.to_s + " SupplementalClaim\n"

            puts("Correct Veteran Relations:\n" + correct_relations)

            # migrate duplicate veteran relations to correct veteran

            error_relations = ""

            as_update_count = as.update_all(veteran_file_number: file_number)

            if as_update_count != as_count
              error_relations += "Expected " + as_count + " Appeals updated, but " + as_update_count + "were updated.\n"
            end

            vbms_id = LegacyAppeal.convert_file_number_to_vacols(file_number)

            las.each do |legapp|
              legapp.case_record.update!(bfcorlid: vbms_id)
              legapp.case_record.folder.update!(titrnum: vbms_id)
              legapp.case_record.correspondent.update!(slogid: vbms_id)
            end

            las_update_count = las.update_all(vbms_id: vbms_id)

            if las_update_count != las_count
              error_relations += "Expected " + las_count + " LegacyAppeals updated, but " + las_update_count + "were updated.\n"
            end

            ahls_update_count = ahls.update_all(veteran_file_number: file_number)

            if ahls_update_count != ahls_count
              error_relations += "Expected " + ahls_count + " HearingLocations updated, but " + ahls_update_count + "were updated.\n"
            end

            bpoas_update_count = bpoas.update_all(file_number: file_number)

            if bpoas_update_count != bpoas_count
              error_relations += "Expected " + bpoas_count + " BgsPowerOfAttorneys updated, but " + as_update_count + "were updated.\n"
            end

            ds_update_count = ds.update_all(file_number: file_number)

            if ds_update_count != ds_count
              error_relations += "Expected " + ds_count + " Documents updated, but " + ds_update_count + "were updated.\n"
            end

            epes_update_count = epes.update_all(veteran_file_number: file_number)

            if epes_update_count != epes_count
              error_relations += "Expected " + epes_count + " EndProductEstablishments updated, but " + epes_update_count + "were updated\n"
            end

            f8s_update_count  = f8s.update_all(file_number: vbms_id)

            if f8s_update_count != f8s_count
              error_relations += "Expected " + f8s_count + " Form8s updated, but " + f8s_update_count + "were updated.\n"
            end

            hlrs_update_count = hlrs.update_all(veteran_file_number: file_number)

            if hlrs_update_count != hlrs_count
              error_relations += "Expected " + hlrs_count + " HigherLevelReviews updated, but " + hlrs_update_count + "were updated.\n"
            end

            is_fn_update_count = is_fn.update_all(veteran_file_number: file_number)

            if is_fn_update_count != is_fn_count
              error_relations += "Expected " + is_fn_count + " Intakes by file number updated, but " + is_fn_update_count + "were updated.\n"
            end

            is_vi_update_count = is_vi.update_all(veteran_id: v2.id)

            if is_vi_update_count != is_vi_count
              error_relations += "Expected " + is_vi_count + " Intakes by veteran id updated, but " + is_vi_update_count + "were updated.\n"
            end

            res_update_count = res.update_all(veteran_file_number: file_number)

            if res_update_count != res_count
              error_relations += "Expected " + res_count + " RampElections updated, but " + res_update_count + "were updated.\n"
            end

            rrs_update_count = rrs.update_all(veteran_file_number: file_number)

            if rrs_update_count != rrs_count
              error_relations += "Expected " + rrs_count + " RampRefilings updated, but " + rrs_update_count + "were updated.\n"
            end

            scs_update_count = scs.update_all(veteran_file_number: file_number)

            if scs_update_count != scs_count
              error_relations += "Expected " + scs_count + " SupplimentalCliams updated, but " + scs_update_count + "were updated.\n"
            end

            if !error_relations.empty?
              puts("There were differences in duplicate relations and update relations.\n")
              puts(error_relations)
              puts("Stoping script here. Need manual intervention\n")
              fail Interrupt
            end

            # Check if duplicate veteran relationships are all gone
            existing_relations = ""
            as = Appeal.where(veteran_file_number: old_file_number)

            as_count = as.count
            if as_count != 0
              existing_relations += as_count.to_s + " Appeal still exists.\n"
            end

            las = LegacyAppeal.where(vbms_id: LegacyAppeal.convert_file_number_to_vacols(old_file_number))

            las_count = las.count
            if las_count != 0
              existing_relations += as_count.to_s + " LegacyAppeal still exists.\n"
            end

            ahls = AvailableHearingLocations.where(veteran_file_number: old_file_number)

            ahls_count = ahls.count
            if ahls_count != 0
              existing_relations += ahls_count.to_s + " AvaialbelHearings still exists.\n"
            end

            bpoas = BgsPowerOfAttorney.where(file_number: old_file_number)

            bpoas_count = bpoas.count

            if bpoas_count != 0
              existing_relations += bpoas_count.to_s + " BgsPowerOfAttorneys still exists.\n"
            end

            ds = Document.where(file_number: old_file_number)

            ds_count = ds.count

            if ds_count != 0
              existing_relations += ds_count.to_s + " Document still exists.\n"
            end

            epes = EndProductEstablishment.where(veteran_file_number: old_file_number)

            epes_count = epes.count

            if epes_count != 0
              existing_relations += epes_count.to_s + " EndProductEstablishment still exists.\n"
            end

            f8s = Form8.where(file_number: LegacyAppeal.convert_file_number_to_vacols(old_file_number))

            f8s_count = f8s.count

            if f8s_count != 0
              existing_relations += f8s_count.to_s + " Form8 still exists.\n"
            end

            hlrs = HigherLevelReview.where(veteran_file_number: old_file_number)

            hlrs_count = hlrs.count

            if hlrs_count != 0
              existing_relations += hlrs_count.to_s + " HilerLevelReview still exists.\n"
            end

            is_fn = Intake.where(veteran_file_number: old_file_number)

            is_fn_count = is_fn.count

            if is_fn_count != 0
              existing_relations += is_fn_count.to_s + " Intake by file_number still exists.\n"
            end

            is_vi = Intake.where(veteran_id: v.id)

            is_vi_count = is_vi.count

            if is_vi_count != 0
              existing_relations += is_vi_count.to_s + " intake by vet id still exists.\n"
            end

            res = RampElection.where(veteran_file_number: old_file_number)

            res_count = res.count

            if res_count != 0
              existing_relations += res_count.to_s + " RampElection still exists.\n"
            end

            rrs = RampRefiling.where(veteran_file_number: old_file_number)

            rrs_count = rrs.count

            if rrs_count != 0
              existing_relations += rrs_count.to_s + " RampRefiling still exists.\n"
            end

            scs = SupplementalClaim.where(veteran_file_number: old_file_number)

            scs_count = scs.count

            if scs_count != 0
              existing_relations += scs_count.to_s + " SupplementalClaim still exists.\n"
            end

            if !existing_relations.empty?
              puts("Duplicate veteran still has associated records. Can not delete untill resolved:\n" + existing_relations)
              fail Interrupt
            end

            # delete duplicate veteran
            v.destroy!

            if Veteran.find_by_file_number(old_file_number).present?
              puts("Veteran failed to be deleted.")
            end
          end

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

            # set current user
            RequestStore[:current_user] = OpenStruct.new(ip_address: "127.0.0.1", station_id: "283", css_id: "CSFLOW", regional_office: "DSUSER")

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

        private

        def convert_file_number_to_legacy(file_number)
          return LegacyAppeal.convert_file_number_to_vacols(file_number)
        end
      end
    end
  end
end
