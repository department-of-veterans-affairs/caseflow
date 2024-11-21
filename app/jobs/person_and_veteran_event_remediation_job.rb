# frozen_string_literal: true

class PersonAndVeteranEventRemediationJob < CaseflowJob
  queue_with_priority :low_priority

  def setup_job
    RequestStore.store[:current_user] = User.system_user
  end

  def perform
    setup_job
    run_person_remediation
    run_veteran_remediation
  end

  private

  def run_person_remediation
    find_events("Person").select do |event_record|
      original_id = event_record.evented_record_id
      dup_ids = Person.where(ssn: event_record.evented_record.ssn).map(&:id).reject { |id| id == original_id }
      if dup_ids.size >= 1
        Remediations::DuplicatePersonRemediationService
          .new(updated_person_id: original_id, duplicate_person_ids: dup_ids).remediate!
      end
    end
  end

  def run_veteran_remediation
    find_events("Veteran").select do |event_record|
      before_fn = event_record.info["before_data"]["file_number"]
      after_fn = event_record.info["record_data"]["file_number"]
      original_id = event_record.evented_record_id
      dup_ids = Veteran.where(ssn: event_record.evented_record.ssn).map(&:id).reject { |id| id == original_id }
      if before_fn != after_fn || dup_ids.size >= 1
        Remediations::VeteranRecordRemediationService.new(before_fn, after_fn, event_record).remediate!
      end
    end
  end

  def find_events(event_type)
    EventRecord.where(evented_record_type: event_type).exists?(["updated_at >= ?", 5.minutes.ago])
  end
end
