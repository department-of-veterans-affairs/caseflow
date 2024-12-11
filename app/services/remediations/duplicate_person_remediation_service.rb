# frozen_string_literal: true

class Remediations::DuplicatePersonRemediationService
  ASSOCIATIONS = [
    Claimant,
    DecisionIssue,
    EndProductEstablishment,
    RequestIssue,
    Notification
  ].freeze

  # Define the parameter struct for remediation audit params
  RemediationAuditParams = Struct.new(:after_data, :before_data, :type, :id)

  def initialize(updated_person_id:, duplicate_person_ids:, event_record:)
    @updated_person_id = updated_person_id
    @duplicate_person_ids = duplicate_person_ids
    @event_record = event_record
  end

  def remediate!
    if find_and_update_records
      duplicate_persons.each(&:destroy!)
      @event_record.remediated!
    else
      @event_record.failed!
    end
    @event_record.remediation_attempts += 1
  end

  private

  attr_reader :duplicate_person_ids, :event_record, :updated_person_id

  class AssociationRemediation
    def initialize(event_record, duplicate_persons, og_person, klass)
      @event_record = event_record
      @duplicate_persons = duplicate_persons
      @klass = klass
      @og_person = og_person
    end

    def call
      column = klass.column_names.find { |name| name.end_with?("participant_id") }
      records = klass.where("#{column}": duplicate_persons.map(&:participant_id))

      records.map do |record|
        before_data = record.attributes
        record.update!("#{column}": og_person.participant_id)
        # Use the parameter object for the audit params
        audit_params = RemediationAuditParams.new(
          record.attributes,  # after_data
          before_data,        # before_data
          record.class.name,  # type
          record.id           # id
        )

        add_remediation_audit(audit_params)
      end
    end

    private

    attr_reader :duplicate_persons, :event_record, :og_person, :klass

    def add_remediation_audit(audit_params)
      EventRemediationAudit.create!(
        event_record: event_record,
        remediated_record_type: audit_params.type,
        remediated_record_id: audit_params.id,
        info: {
          remediation_type: "DuplicatePersonRemediationService",
          after_data: audit_params.after_data,
          before_data: audit_params.before_data
        }
      )
    end
  end

  def find_and_update_records
    begin
      ActiveRecord::Base.transaction do
        ASSOCIATIONS.each do |klass|
          AssociationRemediation.new(event_record, duplicate_persons, og_person, klass).call
        end
      end
    rescue StandardError => error
      # Log the error specific to find_and_update_records and return false
      Rails.logger.error "Error in find_and_update_records: #{error.message}"
      SlackService.new.send_notification("Error in find_and_update_records: #{error.message}",
                                         "Error in #{self.class.name}")
    end
  end

  def duplicate_persons
    @duplicate_persons ||= Person.where(id: duplicate_person_ids)
  end

  def og_person
    @og_person ||= Person.find_by(id: updated_person_id)
  end
end
