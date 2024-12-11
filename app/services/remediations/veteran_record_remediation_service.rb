# frozen_string_literal: true

class Remediations::VeteranRecordRemediationService
  ASSOCIATED_OBJECTS = FixFileNumberWizard::ASSOCIATIONS

  # Define the parameter struct for remediation audit params
  RemediationAuditParams = Struct.new(:class_name, :record_id, :before_data, :after_data)

  # Define the lookup hash for column names
  COLUMN_NAME_LOOKUP = {
    "Appeal" => "veteran_file_number",
    "AvailableHearingLocations" => "veteran_file_number",
    "EndProductEstablishment" => "veteran_file_number",
    "HigherLevelReview" => "veteran_file_number",
    "RampElection" => "veteran_file_number",
    "RampRefiling" => "veteran_file_number",
    "SupplementalClaim" => "veteran_file_number",
    "Intake" => "veteran_file_number",
    "BgsPowerOfAttorney" => "file_number",
    "Form8" => "file_number",
    "Document" => "file_number",
    "LegacyAppeal" => "vbms_id"
  }.freeze

  def initialize(before_fn, after_fn, event_record)
    @before_fn = before_fn
    @after_fn = after_fn
    @event_record = event_record
  end

  def remediate!
    if dups.any? # If there are duplicates, run dup_fix on @after_fn
      if dup_fix(after_fn)
        dups.each(&:destroy!)
        @event_record.remediated!
      end
    elsif fix_vet_records # Otherwise, fix veteran records normally
      @event_record.remediated!
    else
      @event_record.failed!
    end
    @event_record.remediation_attempts += 1
  end

  private

  attr_reader :after_fn, :before_fn, :event_record

  def real_v
    @real_v ||= Veteran.find_by_file_number(after_fn)
  end

  def dups
    @dups ||= Veteran.where(ssn: real_v.ssn).reject { |vet| vet.id == real_v.id }
  end

  def dup_fix(file_number)
    begin
      duplicate_veterans_collections = dups.flat_map { |dup| grab_collections(dup.file_number) }
      update_records!(duplicate_veterans_collections, file_number)
    rescue StandardError => error
      Rails.logger.error "dup_fix failed: #{error.message}"
      SlackService.new.send_notification(
        "Job failed during record update: #{error.message}",
        "Error in #{self.class.name}"
      )
      # sentry log / metabase dashboard
    end
  end

  def fix_vet_records
    # fixes file number
    collections = grab_collections(before_fn)
    update_records!(collections, after_fn)
  end

  class UpdateCollectionRecord
    def initialize(collection, file_number, event_record)
      @collection = collection
      @file_number = file_number
      @event_record = event_record
    end

    def call
      before_data = collection.attributes
      column_name = infer_column_name(collection.class)
      collection.update!(column_name => file_number)
      # Use the struct for the audit params
      audit_params = RemediationAuditParams.new(
        collection.class.name,
        collection.id,
        before_data,
        collection.attributes
      )

      add_remediation_audit(audit_params)
    end

    private

    attr_reader :collection, :file_number, :event_record

    # utilize the lookup hash for column names
    def infer_column_name(klass)
      COLUMN_NAME_LOOKUP[klass.name] || fail("Unknown class: #{klass.name}, cannot determine column.")
    end

    def add_remediation_audit(audit_params)
      EventRemediationAudit.create!(
        event_record: event_record,
        remediated_record_type: audit_params.class_name,
        remediated_record_id: audit_params.record_id,
        info: {
          remediation_type: "VeteranRecordRemediationService",
          after_data: audit_params.after_data,
          before_data: audit_params.before_data
        }
      )
    end
  end

  def update_records!(collections, file_number)
    # update records with updated file_number
    ActiveRecord::Base.transaction do
      collections.each do |collection|
        UpdateCollectionRecord.new(collection, file_number, event_record).call
      end
    end
  end

  def grab_collections(before_fn)
    ASSOCIATED_OBJECTS.map do |klass|
      ::FixFileNumberWizard::Collection.new(klass, before_fn)
    end
  end
end
