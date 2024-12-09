# frozen_string_literal: true

class Remediations::VeteranRecordRemediationService
  ASSOCIATED_OBJECTS = FixFileNumberWizard::ASSOCIATIONS

  def initialize(before_fn, after_fn, event_record)
    @before_fn = before_fn
    @after_fn = after_fn
    @event_record = event_record
  end

  def remediate!
    if dups.any?
      # If there are duplicates, run dup_fix on @after_fn
      if dup_fix(after_fn)
        dups.each(&:destroy!)
      end
    else
      # Otherwise, fix veteran records normally
      fix_vet_records
    end
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
      true
    rescue StandardError => error
      Rails.logger.error "an error occured #{error}"
      SlackService.new.send_notification("Error in find_and_update_records: #{error.message}",
                                         "Error in #{self.class.name}")
      false
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
      collection.update!(file_number)
      add_remediation_audit(
        class_name: collection.class.name,
        record_id: collection.id,
        before_data: before_data,
        after_data: collection.attributes
      )
    end

    private

    attr_reader :collection, :file_number, :event_record

    def add_remediation_audit(class_name:, record_id:, before_data:, after_data:)
      EventRemediationAudit.create!(
        event_record: event_record,
        remediated_record_type: class_name,
        remediated_record_id: record_id,
        info: {
          remediation_type: "VeteranRecordRemediationService",
          after_data: after_data,
          before_data: before_data
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
