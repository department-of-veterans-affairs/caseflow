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
  end

  def remediate!
    if find_and_update_records
      @dup_persons.each(&:destroy!)
    end
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

        add_remediation_audit(
          after_data: record.attributes,
          before_data: before_data,
          id: record.id,
          type: record.class.name
        )
      end
    end

    private

    attr_reader :duplicate_persons, :event_record, :og_person, :klass

    def add_remediation_audit(after_data:, before_data:, type:, id:)
      EventRemediationAudit.create!(
        event_record: event_record,
        remediated_record_type: type,
        remediated_record_id: id,
        info: {
          remediation_type: "DuplicatePersonRemediationService",
          after_data: after_data,
          before_data: before_data
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
