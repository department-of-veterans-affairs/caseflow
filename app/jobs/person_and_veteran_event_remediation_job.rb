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
    find_and_remediate_duplicate_people
    find_and_update_veteran_records
  end

  def find_and_remediate_duplicate_people
    # grabs array of event records for person objects
    event_records = EventRecord.where(evented_record_type: "Person").exists?(["updated_at: >= ?", 5.minutes.ago])
    found_record_ids = []
    event_records.each do |event_record|
      return event_record[info][before_data].empty?
      if event_record[info][before_data][ssn] != event_record[info][record_data][ssn]
        found_record_ids << event_record.evented_record_id
      end
    end
    # wrap with rescue block
    DuplicatePersonRemediationService.new(found_record_ids).remediate
  end

  def find_and_update_veteran_records
    # grabs array of event records for veteran objects
    event_records = EventRecord.where(evented_record_type: "Veteran").exists?(["updated_at: >= ?", 5.minutes.ago])
    found_record_ids = []
    event_records.each do |event_record|
      return event_record[info][before_data].empty?
      if event_record[info][before_data][file_number] != event_record[info][record_data][file_number]
        # kickoff veteran record remediation job
        found_record_ids << event_record.evented_record_id
      end
    end
    # wrap with rescue block
    VeteranRecordRemedationService.new(found_record_ids).remediate
  end
end
