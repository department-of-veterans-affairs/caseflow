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
    find_and_update_records
  end

  private

  def find_and_update_records
    dup_persons = Person.where(id: @duplicate_person_ids)
    og_person = Person.find_by(id: @updated_person_id)

    ASSOCIATIONS.each do |klass|
      update_found_records(klass, dup_persons, og_person)
    end
    # destroy dup_person
  end

  def update_found_records(klass, dup_persons, og_person)
    column = klass.column_names.find { |name| name.end_with?("participant_id") }
    records = klass.where("#{column}": dup_persons.pluck(:participant_id))
    records.update_all("#{column}": og_person.participant_id)
  end
end
