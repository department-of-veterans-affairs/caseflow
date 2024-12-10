# frozen_string_literal: true

class PersonAndVeteranEventRemediationJob < CaseflowJob
  queue_with_priority :low_priority

  def setup_job
    RequestStore.store[:current_user] = User.system_user
  end

  def perform
    setup_job

    [:person, :veteran].each do |subject|
      run_remediation(subject, :active)
      run_remediation(subject, :pending)
    end
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

  def run_person_remediation
    find_active_events(:person).each do |event_record|
      PersonRemediation.new(event_record).call
    end
  end

  def run_remediation(subject, status = :active)
    find_events(subject, status).each do |event_record|
      [subject, "remediation"].join("_").classify.new(event_record).call
    end
  end

  def find_events(event_type, status = :active)
    scope = case status
            when :active
              EventRecord.active
            when :pending
              EventRecord.pending
            else
              EventRecord.scoped
            end

    scope.where(evented_record_type: event_type.to_s.classify)
  end
end
