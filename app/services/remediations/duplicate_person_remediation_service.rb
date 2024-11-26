# frozen_string_literal: true

class Remediations::DuplicatePersonRemediationService
  ASSOCIATIONS = [
    Claimant,
    DecisionIssue,
    EndProductEstablishment,
    RequestIssue,
    Notification
  ].freeze

  def initialize(updated_person_id:, duplicate_person_ids:, event_record:)
    @updated_person_id = updated_person_id
    @duplicate_person_ids = duplicate_person_ids
    @event_record = event_record
    @dup_persons = Person.where(id: duplicate_person_ids)
    @og_person = Person.find_by(id: updated_person_id)
  end

  def remediate!
    if find_and_update_records
      @dup_persons.each(&:destroy!)
    end
  end

  private

  def find_and_update_records
    begin
      ActiveRecord::Base.transaction do
        ASSOCIATIONS.each do |klass|
          column = klass.column_names.find { |name| name.end_with?("participant_id") }
          records = klass.where("#{column}": @dup_persons.map(&:participant_id))
          records.map do |record|
            before_data = record.attributes
            record.update!("#{column}": @og_person.participant_id)
            add_remediation_audit(remediated_record: record,
                                  before_data: before_data,
                                  after_data: record.attributes)
          end
        end
      end
      true
    rescue StandardError => error
      Rails.logger.error "an error occured #{error}"
      false
    end
  end

  def add_remediation_audit(remediated_record:, before_data:, after_data:)
    EventRemediationAudit.create!(
      event_record: @event_record,
      remediated_record_type: remediated_record.class.name,
      remediated_record_id: remediated_record.id,
      # remediated_record: remediated_record,
      info: {
        remediation_type: "DuplicatePersonRemediationService",
        after_data: after_data,
        before_data: before_data
      }
    )
  end
end
