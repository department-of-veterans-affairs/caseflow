# frozen_string_literal: true

class Remediations::DuplicatePersonRemediationService
  ASSOCIATIONS = [
    Claimant,
    DecisionIssue,
    EndProductEstablishment,
    RequestIssue,
    Notification
  ].freeze

  def initialize(updated_person_id:, duplicate_person_ids:)
    @updated_person_id = updated_person_id
    @duplicate_person_ids = duplicate_person_ids
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
      @dup_persons = Person.where(id: @duplicate_person_ids)
      og_person = Person.find_by(id: @updated_person_id)

      ActiveRecord::Base.transaction do
        ASSOCIATIONS.each do |klass|
          column = klass.column_names.find { |name| name.end_with?("participant_id") }
          records = klass.where("#{column}": @dup_persons.map(&:participant_id))
          records.update_all("#{column}": og_person.participant_id)
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
end
