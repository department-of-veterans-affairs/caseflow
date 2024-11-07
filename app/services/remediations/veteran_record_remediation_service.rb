# frozen_string_literal: true

require_relative "../../../lib/helpers/fix_file_number_wizard"

class Remediations::VeteranRecordRemediationService
  ASSOCIATED_OBJECTS = FixFileNumberWizard::ASSOCIATIONS

  def initialize(before_fn, after_fn)
    @before_fn = before_fn
    @after_fn = after_fn
  end

  def remediate!
    fix_vet_records
  end

  private

  def fix_vet_records
    # fixes file number
    collections = FixfileNumberCollections.grab_collections(@before_fn)
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
end

class FixfileNumberCollections
  ASSOCIATED_OBJECTS = FixFileNumberWizard::ASSOCIATIONS
  def self.grab_collections(before_fn)
    ASSOCIATED_OBJECTS.map do |klass|
      FixFileNumberWizard::Collection.new(klass, before_fn)
    end
  end
end
