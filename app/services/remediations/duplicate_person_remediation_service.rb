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
    begin
      if find_and_update_records
        @dup_persons.each(&:destroy!)
      else
        Rails.logger.error "find_and_update_records failed"
        SlackService.new.send_notification("Job failed during record update", "Error in #{self.class.name}")
        false
      end
    rescue StandardError => error
      # This will catch any errors that happen during the execution of find_and_update_records or subsequent operations
      Rails.logger.error "An error occurred during remediation: #{error.message}"
      SlackService.new.send_notification("Job failed during remediation: #{error.message}", "Error in #{self.class.name}")
      false # Indicate failure
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
      true # Successfully completed, return true
    rescue StandardError => error
      # Log the error specific to find_and_update_records and return false
      Rails.logger.error "Error in find_and_update_records: #{error.message}"
      SlackService.new.send_notification("Error in find_and_update_records: #{error.message}",
                                         "Error in #{self.class.name}")
      false # Indicate failure
    end
  end

  def add_remediation_audit(remediated_record:, before_data:, after_data:)
    EventRemediationAudit.create!(
      event_record: @event_record,
      remediated_record_type: remediated_record.class.name,
      remediated_record_id: remediated_record.id,
      info: {
        remediation_type: "DuplicatePersonRemediationService",
        after_data: after_data,
        before_data: before_data
      }
    )
  end
end
