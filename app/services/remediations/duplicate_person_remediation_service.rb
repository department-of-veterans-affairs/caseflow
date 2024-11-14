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
    if find_and_update_records
      @dup_persons.each(&:destroy!)
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
      true
    rescue StandardError => error
      Rails.logger.error "an error occured #{error}"
      false
    end
  end
end
