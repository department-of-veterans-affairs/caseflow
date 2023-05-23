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

  class OutcodeWithMismatchedVeteranName
    def run_remediation_by_veteran_id(veteran_id)
      vnu = VeteranNameUpdater.new
      vnu.run_remediation_by_veteran_id(veteran_id)
    end
  end
end
