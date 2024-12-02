# frozen_string_literal: true

require_relative "../../../lib/helpers/fix_file_number_wizard"

class Remediations::VeteranRecordRemediationService
  ASSOCIATED_OBJECTS = FixFileNumberWizard::ASSOCIATIONS

  def initialize(before_fn, after_fn)
    @before_fn = before_fn
    @after_fn = after_fn
  end

  def remediate!
    begin
      real_v = Veteran.find_by_file_number(@after_fn)
      @dups = Veteran.where(ssn: real_v.ssn).reject { |v| v.id == real_v.id }

      if @dups.any?
        # If there are duplicates, run dup_fix on @after_fn
        if dup_fix(@after_fn)
          @dups.each(&:destroy!)
        else
          Rails.logger.error "dup_fix failed"
          SlackService.new.send_notification("Job failed during record update", "Error in #{self.class.name}")
          false
        end
      else
        # Otherwise, fix veteran records normally
        fix_vet_records
      end
    rescue StandardError => error
      # This will catch any errors that happen during the execution of find_and_update_records or subsequent operations
      Rails.logger.error "An error occurred during remediation: #{error.message}"
      SlackService.new.send_notification("Job failed during remediation: #{error.message}", "Error in #{self.class.name}")
      false # Indicate failure
    end
  end

  private

  def dup_fix(file_number)
    begin
      duplicate_veterans_collections = @dups.flat_map { |dup| grab_collections(dup.file_number) }
      update_records!(duplicate_veterans_collections, file_number)
      # SlackService.new.send_notification("Job completed successfully", self.class.name)
      true
    rescue StandardError => error
      Rails.logger.error "an error occured #{error}"
      SlackService.new.send_notification("Job failed with error: #{error.message}", "Error in #{self.class.name}")
      false # Indicate failure
      # sentry log / metabase dashboard
    end
  end

  def fix_vet_records
    # fixes file number
    collections = grab_collections(@before_fn)
    update_records!(collections, @after_fn)
  end

  def update_records!(collections, file_number)
    # update records with updated file_number
    ActiveRecord::Base.transaction do
      collections.each do |collection|
        collection.update!(file_number)
      end
    end
  end

  def grab_collections(before_fn)
    ASSOCIATED_OBJECTS.map do |klass|
      FixFileNumberWizard::Collection.new(klass, before_fn)
    end
  end
end
