=begin
End Products in VBMS get established (through the processing of End Product Establishments in Caseflow)
and if a duplicateEP error is caught it gets logged and prevents syncing with our external services when there
statuses were cancelled or cleared; we must perform a manual remediation script to handle these failed requests or a automation script.

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
            check_by_ama_appeal_uuid(uuid)
          rescue => e
            puts e.message
            retry
          end

          # Find the appeal with the given UUID
          def check_by_ama_appeal_uuid(uuid)
            a = Appeal.find_by_uuid(uuid)

            if a.nil?
              puts("Appeal was not found. Aborting")
              fail Interrupt
            elsif a.veteran.nil?
              puts("veteran is not assiciated to this appeal. Aborting...")
              fail Interrupt
            elsif a.veteran.file_number.empty?
              puts("Veteran tied to appeal does not have a file_number. Aborting..")
              fail Interrupt
            end

            check_by_duplicate_veteran_file_number(a.veteran.file_number)
          end

          def run_remediation_by_ama_appeal_uuid(appeal_uuid)
            a = Appeal.find_by_uuid(appeal_uuid)

            if a.nil?
              puts("Appeal was not found. Aborting")
              fail Interrupt
            elsif a.veteran.nil?
              puts("veteran is not assiciated to this appeal. Aborting...")
              fail Interrupt
            elsif a.veteran.file_number.empty?
              puts("Veteran tied to appeal does not have a file_number. Aborting..")
              fail Interrupt
            end

            run_remediation(a.veteran.file_number)
          end

          def check_by_duplicate_veteran_file_number(duplicate_veteran_file_number)
            # check if only one vet has the old file number
            vets = Veteran.where(file_number: duplicate_veteran_file_number)

            # Check that only one vet has the bad file number
            if vets.nil? || vets.count > 1
              puts("More than on vet with the duplicate veteran file number exists. Aborting..")
              fail Interrupt
            end

            # Get the duplicate veteran into memory
            v = Veteran.find_by_file_number(duplicate_veteran_file_number)

            # Set variable to hold old file_number (file number on duplicate veteran)
            old_file_number = v.file_number

            # Check if veteran is not found
            if v.nil?
              puts("No veteran found. Aborting.")
              fail Interrupt
            end

            # Check if there in fact duplicate veterans. Can be duplicated with
            # same partipant id or ssn
            dupe_vets = Veteran.where("ssn = ? or participant_id = ?", v.ssn, v.participant_id)

            v2 = nil

            vet_ssn = v.ssn
            # checks if we get no vets or less than 2 vets}
            if dupe_vets.nil? || dupe_vets.count < 2
              puts("No duplicate veteran found")
              fail Interrupt
            elsif dupe_vets.count > 2 # check if we get more than 2 vets back
              puts("More than two veterans found. Aborting")
              fail Interrupt
            else
              other_v = dupe_vets.first # grab first of the dupilicates and check if the duplicate veteran}
              if other_v.file_number == old_file_number
                other_v = dupe_vets.last # First is duplicate veteran so get 2nd
              end
              if other_v.file_number.empty? || other_v.file_number == old_file_number #if correct veteran has wrong file number
                puts("Both veterans have the same file_number or No file_number on the correct veteran. Aborting...")
                fail Interrupt
              elsif v.ssn.empty? && !other_v.ssn.empty?
                vet_ssn = other_v.ssn
              elsif v.ssn.empty? && other_v.ssn.empty?
                puts("Neither veteran has a ssn and a ssn is needed to check the BGS file number. Aborting")
                fail Interrupt
              elsif !other_v.ssn.empty? && v.ssn != other_v.ssn
                puts("Veterans do not have the same ssn and a correct ssn needs to be chosen. Aborting.")
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
              puts("File number from BGS does not match correct veteran record. Aborting...")
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
              puts("More than on vet with the duplicate veteran file number exists. Aborting..")
              fail Interrupt
            end

            # Get the duplicate veteran into memory
            v = Veteran.find_by_file_number(duplicate_veteran_file_number)

            # Set variable to hold old file_number (file number on duplicate veteran)
            old_file_number = v.file_number

            # Check if veteran is not found
            if v.nil?
              puts("No veteran found. Aborting.")
              fail Interrupt
            end

            # Check if there in fact duplicate veterans. Can be duplicated with
            # same partipant id or ssn
            dupe_vets = Veteran.where("ssn = ? or participant_id = ?", v.ssn, v.participant_id)

            v2 = nil

            vet_ssn = v.ssn
            # checks if we get no vets or les sthan 2 vets}
            if dupe_vets.nil? || dupe_vets.count < 2
              puts("No duplicate veteran found")
              fail Interrupt
            elsif dupe_vets.count > 2 # check if we get more than 2 vets back
              puts("More than two veterans found. Aborting")
              fail Interrupt
            else
              other_v = dupe_vets.first # grab first of the dupilicates and check if the duplicate veteran}
              if other_v.file_number == old_file_number
                other_v = dupe_vets.last # First is duplicate veteran so get 2nd
              end
              if other_v.file_number.empty? || other_v.file_number == old_file_number #if correct veteran has wrong file number
                puts("Both veterans have the same file_number or No file_number on the correct veteran. Aborting...")
                fail Interrupt
              elsif v.ssn.empty? && !other_v.ssn.empty?
                vet_ssn = other_v.ssn
              elsif v.ssn.empty? && other_v.ssn.empty?
                puts("Neither veteran has a ssn and a ssn is needed to check the BGS file number. Aborting")
                fail Interrupt
              elsif !other_v.ssn.empty? && v.ssn != other_v.ssn
                puts("Veterans do not have the same ssn and a correct ssn needs to be chosen. Aborting.")
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
              puts("File number from BGS does not match correct veteran record. Aborting...")
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
              puts("There were differences in duplicate relations and update relations.")
              puts(error_relations)
              puts("Stoping script here. Need manual intervention")
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

          # This code finds the Veteran associated with the given UUID, then finds the SupplementalClaims and HigherLevelReviews associated with the Veteran.
          # It then filters these to only include the claims with establishment errors containing "duplicateep",
          # and joins them based on their associated EndProduct records.
          # The resulting ActiveRecord::Relation object is stored in problem_claims, which can be used for further processing as needed.

          puts("We have checked for duplicate file records based upon your appeal and made necessary adjustments. It is now recommended to
            cancel the sink job of the appeal with the duplicateEP error. Please enter uuid of appeal to cancel the sink job for: \n")

          begin
            UUID_REGEX = /^\h{8}-\h{4}-\h{4}-\h{4}-\h{12}$/i
            uuid2 = gets.chomp.strip

            unless uuid2.match?(UUID_REGEX)
              raise "Invalid UUID format. Please enter a valid UUID."
            end

            # Get SupplementalClaim or HigherLevelReview with a specific uuid
            sc = SupplementalClaim.find_by_uuid(uuid2)
            hlr = HigherLevelReview.find_by_uuid(uuid2)

            # Check if the uuid exists in either table
            unless sc || hlr
              puts "No SupplementalClaim or HigherLevelReview found with uuid: #{uuid}"
              return
            end

            puts "Running match query for SC or HLRs that contain duplicateEP Errors"

            # set current user
            RequestStore[:current_user] = OpenStruct.new(ip_address: "127.0.0.1", station_id: "283", css_id: "CSFLOW", regional_office: "DSUSER")

            # Sets the variable End Product Establishment by the reference_id/Claim ID
            scs = SupplementalClaim.where("establishment_error ILIKE '%duplicateep%'")
            hlr = HigherLevelReview.where("establishment_error ILIKE '%duplicateep%'")

            # Grabs the problem suppliment claims with the status of Cancelled or Cleared
            problem_scs = scs.select { |sc|
            sc.veteran.end_products.select { |ep|
            ep.claim_type_code.include?("040") && ["CAN", "CLR"].include?(ep.status_type_code) &&
            [Date.today, 1.day.ago.to_date].include?(ep.last_action_date)}.empty?}

            # Grabs the problem suppliment claims with the status of Cancelled or Cleared
            problem_hlr = hlr.select { |hlr|
            hlr.end_products.select { |ep|
            ep.claim_type_code.include?("030") && ["CAN", "CLR"].include?(ep.status_type_code) &&
            [Date.today, 1.day.ago.to_date].include?(ep.last_action_date)}.empty?}

            # Count the total problem claims and keep track
            count = problem_scs.count + problem_hlr.count

            # Check if the uuid is part of the problem claims
            if
            (problem_scs = SupplementalClaim.where("establishment_error ILIKE '%duplicateep%'")
              .where(id: sc&.id)) ||
            (problem_hlr = HigherLevelReview.where("establishment_error ILIKE '%duplicateep%'")
              .where(id: hlr&.id)) === true;
              then
              puts "uuid is part of the problem claims, total problem claims count to be displayed below"
            else
              puts "The uuid provided does not match a problem claim with duplicateEP error"
              fail Interrupt
            end

            # Join the problem SupplementalClaims and HigherLevelReviews
            problem_claims = problem_scs.joins(:end_products)
            .where(end_products: { claim_type_code: "040", status_type_code: ["CAN", "CLR"], last_action_date: [Date.today, 1.day.ago.to_date] })
            .merge(problem_hlr.joins(:end_products)
            .where(end_products: { claim_type_code: "030", status_type_code: ["CAN", "CLR"], last_action_date: [Date.today, 1.day.ago.to_date] }))

            # Count the total problem claims and keep track
            count = problem_claims.count

            if count > 0
            Rails.logger.info("Found #{count} problem Supplemental Claims and/or Higher Level Reviews we are tracking and if you run remediation steps successfully,
              this cound should reduce by one, please review the claim data, and select yes or no next if you would like to cancel or clear the sync status")
            else
            Rails.logger.info("No problem claims found. You can end your terminal session now.")
            end

            unless
          rescue => e
            puts e.message
            retry
          end

          # If it shows up. We want to pp all data.

          # Prompt user to enter yes or no to fix the data manually by manually updating the caseflow sync status.

          # If no appeal is found in the table. Prompt the user that the appeal UUID is invalid as no duplicate EP error exists for that appeal.

          # PP Appeal Data

          # Prompt user if he recogonizes change to the Appeal and if he would like to manually up update the sync status by performing.

          private

          def convert_file_number_to_legacy(file_number)
            return LegacyAppeal.convert_file_number_to_vacols(file_number)
          end
        end
      end
    end
  end
end
