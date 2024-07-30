# frozen_string_literal: true

UUID_REGEX = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/.freeze

module WarRoom
  def self.user
    # rubocop:disable Style/ClassVars
    @@user ||= OpenStruct.new(
      ip_address: "127.0.0.1",
      station_id: "283",
      css_id: "CSFLOW",
      regional_office: "DSUSER"
    )
    # rubocop:enable Style/ClassVars
  end

  class Outcode
    def ama_run(identifier)
      # set current user
      RequestStore[:current_user] = OpenStruct.new(
        ip_address: "127.0.0.1",
        station_id: "283",
        css_id: "CSFLOW",
        regional_office: "DSUSER"
      )

      appeal = find_ama_appeal(identifier)

      if appeal.nil?
        puts("No appeal was found for that identifier. Aborting...")
        fail Interrupt
      end

      # view task tree
      appeal.treee

      FixFileNumberWizard.run(appeal: appeal)
      # need to do y or q
    end

    def legacy_run(vacols_id)
      # set current user
      RequestStore[:current_user] = OpenStruct.new(
        ip_address: "127.0.0.1",
        station_id: "283",
        css_id: "CSFLOW",
        regional_office: "DSUSER"
      )

      # set appeal parameter
      appeal = LegacyAppeal.find_by_vacols_id(vacols_id)

      if appeal.nil?
        puts("No appeal was found for that vacols id. Aborting...")
        fail Interrupt
      end

      # view task tree
      appeal.treee

      FixFileNumberWizard.run(appeal: appeal)
      # need to do y or q
    end

    private

    def find_ama_appeal(identifier)
      if identifier.match?(UUID_REGEX)
        Appeal.find_by(uuid: identifier)
      else
        Appeal.find_by(veteran_file_number: identifier)
      end
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
end
