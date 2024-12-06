# frozen_string_literal: true

class PersonAndVeteranEventRemediationJob < CaseflowJob
  queue_with_priority :low_priority

  class PersonAndVeteranRemediationJobError < StandardError; end

  # retry_on(PersonAndVeteranRemediationJobError, attempts: 3, wait: :exponentially_longer) do |job, exception|
  #   Rails.logger.error("#{job.class.name} (#{job.job_id}) failed with error: #{exception.message}")
  # end
  retry_on PersonAndVeteranEventRemediationJob::PersonAndVeteranRemediationJobError, wait: 5.seconds, attempts: 3

  def setup_job
    RequestStore.store[:current_user] = User.system_user
  end

  def perform
    setup_job
    run_person_remediation
    run_veteran_remediation
  end

  private

  class PersonRemediation
    def initialize(event_record)
      @event_record = event_record
    end

    def call
      if duplicate_ids.size >= 1
        Remediations::DuplicatePersonRemediationService.new(
          duplicate_person_ids: duplicate_ids,
          event_record: event_record,
          updated_person_id: original_id
        ).remediate!
      end
    end

    private

    attr_reader :event_record

    def duplicate_ids
      @duplicate_ids ||= Person.where(ssn: ssn).map(&:id).reject { |id| id == original_id }
    end

    def ssn
      event_record.evented_record.ssn
    end

    def original_id
      @original_id ||= event_record.evented_record_id
    end
  end

  def run_person_remediation
    find_events("Person").select do |event_record|
      PersonRemediation.new(event_record).call
    end
  end

  class VeteranRemediation
    def initialize(event_record)
      @event_record = event_record
    end

    def call
      if before_file_num != after_file_num || duplicate_ids.size >= 1
        Remediations::VeteranRecordRemediationService.new(
          before_file_num,
          after_file_num,
          event_record
        ).remediate!
      end
    begin
      find_events("Person").select do |event_record|
        original_id = event_record.evented_record_id
        dup_ids = Person.where(ssn: event_record.evented_record.ssn).map(&:id).reject { |id| id == original_id }
        if dup_ids.size >= 1
          Remediations::DuplicatePersonRemediationService
            .new(updated_person_id: original_id, duplicate_person_ids: dup_ids, event_record: event_record).remediate!
        end
      end
    rescue StandardError => error
      raise PersonAndVeteranEventRemediationJob::PersonAndVeteranRemediationJobError, "Error occurred: #{error.message}"
    end

    private

    attr_reader :event_record

    def duplicate_ids
      Veteran.where(ssn: ssn).map(&:id).reject { |id| id == original_id }
    end

    def ssn
      event_record.evented_record.ssn
    end

    def before_file_num
      @before_file_num ||= event_record.info["before_data"]["file_number"]
    end

    def after_file_num
      @after_file_num ||= event_record.info["record_data"]["file_number"]
    end

    def original_id
      @original_id ||= event_record.evented_record_id
    end
  end

  def run_veteran_remediation
    find_events("Veteran").select do |event_record|
      VeteranRemediation.new(event_record).call
    begin
      find_events("Veteran").select do |event_record|
        before_fn = event_record.info["before_data"]["file_number"]
        after_fn = event_record.info["record_data"]["file_number"]
        original_id = event_record.evented_record_id
        dup_ids = Veteran.where(ssn: event_record.evented_record.ssn).map(&:id).reject { |id| id == original_id }
        if before_fn != after_fn || dup_ids.size >= 1
          Remediations::VeteranRecordRemediationService.new(before_fn, after_fn, event_record).remediate!
        end
      end
    rescue StandardError => error
      raise PersonAndVeteranEventRemediationJob::PersonAndVeteranRemediationJobError, "Error occurred: #{error.message}"
    end
  end

  def find_events(event_type)
    EventRecord.where(evented_record_type: event_type).exists?(["updated_at >= ?", 5.minutes.ago])
  end
end
