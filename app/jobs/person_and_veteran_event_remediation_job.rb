# frozen_string_literal: true

require_relative "../../lib/helpers/fix_file_number_wizard"
# require_relative "../../lib/helpers/duplicate_veteran_checker"

class PersonAndVeteranEventRemediationJob < CaseflowJob
  queue_with_priority :low_priority

  def setup_job
    RequestStore.store[:current_user] = User.system_user
  end

  def perform
    setup_job
    if dups = find_and_remediate_duplicate_people
      DuplicatePersonRemediationService.new(dups).remediate
    end

    find_and_update_veteran_records
  end

  private

  def find_duplicates

  def find_duplicate_people
    # grabs array of event records for person objects
    find_events("Person").select do |event_record|
      # logic for remediation selection
      others_with_original = Person.where(ssn: event_record.evented_record.ssn)&.map(&:id)&.uniq
      DuplicatePersonRemediationService.new(others_with_original).remediate! if others_with_original.size > 1
    end
  end

  def find_events(event_type)
    EventRecord.where(evented_record_type: event_type).exists?(["updated_at >= ?", 5.minutes.ago])
  end

  def find_and_update_veteran_records
    # grabs array of event records for veteran objects
    event_records = find_events("Veteran")

    found_record_ids = []
    event_records.each do |event_record|
      if event_record[info][before_data][file_number] != event_record[info][record_data][file_number]
        found_record_ids << event_record.evented_record_id
      else
        event_record[info][before_data].empty?
        false
      end
    end
    # kickoff veteran record remediation job
    # wrap with rescue block
    VeteranRecordRemedationService.new(found_record_ids).remediate
  end
end
