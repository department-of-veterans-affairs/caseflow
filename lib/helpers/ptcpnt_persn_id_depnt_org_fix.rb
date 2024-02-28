# frozen_string_literal: true

class PtcpntPersnIdDepntOrgFix < CaseflowJob
  ERROR_TEXT = "participantPersonId does not match a dependent or an organization"

  ASSOCIATIONS = [
    BgsPowerOfAttorney,
    BgsAttorney,
    CavcRemandsAppellantSubstitution,
    Claimant,
    DecisionIssue,
    EndProductEstablishment,
    Notification,
    Organization,
    Person,
    RequestIssue,
    VbmsDistribution,
    Veteran
  ].freeze

  def initialize(stuck_job_report_service)
    @stuck_job_report_service = stuck_job_report_service
  end

  def start_processing_records
    return if error_records.blank?

    # count of records with errors before fix
    @stuck_job_report_service.append_record_count(error_records.count, ERROR_TEXT)

    error_records.each do |sc|
      incorrect_pid = sc.claimant.participant_id
      # check that claimant type is VeteranClaimant
      next unless sc.claimant.type == "VeteranClaimant"

      veteran_file_number = sc.veteran.file_number
      correct_pid = retrieve_correct_pid(veteran_file_number)

      handle_person_and_claimant_records(correct_pid, sc)
      retrieve_records_to_fix(correct_pid, incorrect_pid)

      #Re-run job after fixing broken records
      re_run_job(sc)
    end
    # record count with errors after fix
    @stuck_job_report_service.append_record_count(error_records.count, ERROR_TEXT)
  end

  def handle_person_and_claimant_records(correct_pid, sc)
    correct_person_record = get_correct_person(correct_pid)
    incorrect_person_record = sc.claimant.person

    ActiveRecord::Base.transaction do
      if correct_person_record.present?
        claimants_array_to_be_moved_to = correct_person_record.claimants
        claimants_array_to_remove_claimants_from = incorrect_person_record.claimants

        claimants_array_to_be_moved_to << claimants_array_to_remove_claimants_from

        #Reset the Incorrect Person's Claimant's array before destroying Incorrect Person record
        claimants_array_to_remove_claimants_from = []
        incorrect_person_record.destroy!
      else
        incorrect_person_record.update(participant_id: correct_pid)
      end

      if sc.claimant.payee_code != "00"
        sc.claimant.update(payee_code: "00")
      end

    rescue StandardError => error
      log_error(error)
      @stuck_job_report_service.append_error(sc.class.name, sc.id, error)
    end
  end

  def get_correct_person(correct_pid)
    Person.find_by(participant_id: correct_pid)
  end

  def retrieve_correct_pid(veteran_file_number)
    begin
      hash = BGSService.new.fetch_veteran_info(veteran_file_number)
      hash[:ptcpnt_id]
    rescue StandardError => error
      message = "Error retrieving participant ID for veteran file number #{veteran_file_number}: #{error}"
      @stuck_job_report_service.logs.push(message)
      log_error(error)
    end
  end

  def retrieve_records_to_fix(correct_pid, incorrect_pid)
    incorrectly_associated_records = []
    # correct_person_record = Person.find_by(participant_id: correct_pid)
    # incorrect_person_record = Person.find_by(participant_id: incorrect_pid)

    iterate_through_associations_with_bad_pid(incorrect_pid, incorrectly_associated_records)

    incorrectly_associated_records.each do |record|
      fix_record(record, correct_pid)
    end
  end

  def re_run_job(sc)
    begin
      DecisionReviewProcessJob.perform_now(sc)
    rescue StandardError => error
      @stuck_job_report_service.append_error(sc.class.name, sc.id, error)
      log_error(error)
    end
  end

  def iterate_through_associations_with_bad_pid(incorrect_pid, incorrectly_associated_records)
    ASSOCIATIONS.each do |ass|
      if ass.attribute_names.include?("participant_id")
        records = ass.where(participant_id: incorrect_pid)
        incorrectly_associated_records.push(*records)
      elsif ass.attribute_names.include?("claimant_participant_id")
        records = ass.where(claimant_participant_id: incorrect_pid)
        incorrectly_associated_records.push(*records)
      elsif ass.attribute_names.include?("veteran_participant_id")
        records = ass.where(veteran_participant_id: incorrect_pid)
        incorrectly_associated_records.push(*records)
      end
    end
  end

  def fix_record(record, correct_pid)
    if record.attribute_names.include?("participant_id")
      process_participant_id_record(record, correct_pid)
    elsif record.attribute_names.include?("claimant_participant_id")
      process_claimant_participant_id_record(record, correct_pid)
    elsif record.attribute_names.include?("veteran_participant_id")
      process_veteran_participant_id_record(record, correct_pid)
    end
  end

  def process_participant_id_record(record, correct_pid)
    ActiveRecord::Base.transaction do
      record.update(participant_id: correct_pid)
    rescue StandardError => error
      log_error(error)
      @stuck_job_report_service.append_error(record.class.name, record.id, error)
    end
  end

  def process_claimant_participant_id_record(record, correct_pid)
    ActiveRecord::Base.transaction do
      record.update(claimant_participant_id: correct_pid)
    rescue StandardError => error
      log_error(error)
      @stuck_job_report_service.append_error(record.class.name, record.id, error)
    end
  end

  def process_veteran_participant_id_record(record, correct_pid)
    ActiveRecord::Base.transaction do
      record.update(veteran_participant_id: correct_pid)
    rescue StandardError => error
      log_error(error)
      @stuck_job_report_service.append_error(record.class.name, record.id, error)
    end
  end

  def error_records
    SupplementalClaim.where("establishment_error ILIKE ?", "%#{ERROR_TEXT}%")
  end
end
