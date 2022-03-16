# frozen_string_literal: true

module WarRoom
  def self.user
    @@user ||= OpenStruct.new(ip_address: "127.0.0.1", station_id: "283", css_id: "CSFLOW", regional_office: "DSUSER")
  end

  class Outcode
    def ama_run(uuid_pass_in)
      # set current user
      RequestStore[:current_user] = OpenStruct.new(ip_address: "127.0.0.1", station_id: "283", css_id: "CSFLOW", regional_office: "DSUSER")

      uuid = uuid_pass_in
      # set appeal parameter
      appeal = Appeal.find_by_uuid(uuid)

      if appeal.nil?
        puts("No appeal was found for that uuid. Aborting...")
        fail Interrupt
      end

      # view task tree
      appeal.treee

      # set decision document variable
      dd = appeal.decision_document

      FixFileNumberWizard.run(appeal: appeal)
      #need to do y or q
    end

    def legacy_run(vacols_id)
      # set current user
      RequestStore[:current_user] = OpenStruct.new(ip_address: "127.0.0.1", station_id: "283", css_id: "CSFLOW", regional_office: "DSUSER")

      # set appeal parameter
      appeal = LegacyAppeal.find_by_vacols_id(vacols_id)

      if appeal.nil?
        puts("No appeal was found for that vacols id. Aborting...")
        fail Interrupt
      end

      # view task tree
      appeal.treee

      FixFileNumberWizard.run(appeal: appeal)
      #need to do y or q
    end
  end

  class OutcodeWithDuplicateVeteran
    def run_check_by_ama_uuid(uuid)
      dvc = DuplicateVeteranChecker.new
      dvc.check_by_ama_appeal_uuid(uuid)
    end

    def run_check_by_vacols_id(vacols_id)
      dvc = DuplicateVeteranChecker.new
      dvc.check_by_legacy_appeal_vacols_id(vacols_id)
    end

    def run_check_by_duplicate_veteran_file_number(duplicate_veteran_file_number)
      dvc = DuplicateVeteranChecker.new
      dvc.check_by_duplicate_veteran_file_number(duplicate_veteran_file_number)
    end

    def run_remediation_by_duplicate_veteran_file_number(duplicate_veteran_file_number)
      dvc = DuplicateVeteranChecker.new
      dvc.run_remediation(duplicate_veteran_file_number)
    end

    def run_remediation_by_ama_appeals_uuid(uuid)
      dvc = DuplicateVeteranChecker.new
      dvc.run_remediation_by_ama_appeal_uuid(uuid)
    end

    def run_remediation_by_vacols_id(vacols_id)
      dvc = DuplicateVeteranChecker.new

      dvc.run_remediation_by_vacols_id(vacols_id)
    end
  end

  class OutcodeWithDuplicateEP
    # method for all the epe steps in case there's multiple
    def load_epe(epe, claim_type)
      ep2e = epe.send(:end_product_to_establish)

      epmf = EndProductModifierFinder.new(epe, v)
      taken = epmf.send(:taken_modifiers)

      epmf.instance_variable_set(:@taken_modifiers, taken.push(ep2e.modifier))

      ep2e.modifier = epmf.find

      epe.instance_variable_set(:@end_product_to_establish, ep2e)

      # If the output from the above step is => true, then the end product establishment has succeeded. Proceed with Step 17.
      # If the output from the above step is the DuplicateEP error then we do not have the next available modifier. This Higher Level Review needs sent over to Martin Menchey for remediation.
      if !epe.establish!
        abort("Duplicate EP. Needs remediation.")
      end

      # Check the End Product Establishments count
      puts claim_type.end_product_establishments.count

      # Reload the End Product Establishments
      claim_type.end_product_establishments.each{ |epe| epe.reload }
    end

    def higher_level_review_duplicate_ep(uuid)
      RequestStore[:current_user] = OpenStruct.new(ip_address: "127.0.0.1", station_id: "283", css_id: "CSFLOW", regional_office: "DSUSER")

      hlr = HigherLevelReview.find(uuid)
      if hlr.nil?
        puts("No Higher Level Review was found. Aborting...")
        fail Interrupt
      end
      # Set Veteran for this Higher Level Review
      v = hlr.veteran

      # If the output shows all ten options for the 030 modifier, then all available modifiers are taken. This Higher Level Review needs sent over to Martin Menchey for remediation.
      if v.end_products.map(&:modifier).count == 10
        abort("All available modifiers are taken. Needs to be sent for remdiation.")
      end

      # If the above output does not show all ten options for the 030 then proceed with below
      # Set the End Product Establishments Parameter
      epes = hlr.end_product_establishments

      # If there was only one, which is usually the case, we will only do the below first command.
      # If there was more than one, we will repeat the below command for the subsequent EPES and all subsequent epe steps will need to be duplicated
      # ie second, third, etc
      epes.each { |epe| load_epe(epe, hlr) }

      # Run the Decision Review Process Job
      DecisionReviewProcessJob.new.perform(hlr)

      hlr.reload
      # Check the Establishment Error on the Higher Level Review
      puts hlr.establishment_error
    end

    def supplemental_claim_duplicate_ep(claim_id)
      # set current user
      RequestStore[:current_user] = OpenStruct.new(ip_address: "127.0.0.1", station_id: "283", css_id: "CSFLOW", regional_office: "DSUSER")

      sc = SupplementalClaim.find(claim_id)

      if sc.nil?
        puts("No supplemental claim was found for the following id " + sc)
      end

      # Validate that DuplicateEP is the error on this claim
      sc.establishment_error

      # Set Veteran for this Supplemental Claim
      v = sc.veteran

      # If the above output shows all ten options for the 040 modifier, then all available modifiers are taken. This Supplemental Claim needs sent over to Martin Menchey for remediation.
      if v.end_products.map(&:modifier).count == 10
        abort("All available modifiers are taken. Needs to be sent for remdiation.")
      end

      # Set the End Product Establishments Parameter
      epes = sc.end_product_establishments

      epes.each { |epe| load_epe(epe, hlr) }

      # Run the Decision Review Process Job
      DecisionReviewProcessJob.new.perform(sc)

      # Reload the Supplemental Claim
      sc.reload

      # Check the Establishment Error on the Supplemental Claim
      sc.establishment_error

    end
  end 
end