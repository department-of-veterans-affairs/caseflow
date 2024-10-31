# frozen_string_literal: true

require_relative "../../lib/helpers/fix_file_number_wizard"

class Remediations::VeteranRecordRemediationService
  ASSOCIATED_OBJECTS = FixFileNumberWizard::ASSOCIATIONS

  def intitialize(vet_ids)
    @vet_ids = vet_ids
  end

  def remediate!
    # in this method we will implement some logic to find and update records associated
    # with veterans that have updated file numbers
    # will check by file number and possibly other
    updated_veterans.map do |veteran|
      fix_vet(veteran)
    end
  end

  def fix_vet(veteran)
    # fixes file numebr
    collections = FixfileNumberCollections.get_collections(veteran)
    update_records!(collections, veteran.file_number)
  end

  def updated_veterans
    vet_ids.map do |id|
      Veteran.find(id)
    end
  end

  def update_records!(collections, file_number)
    ActiveRecord::Base.transaction do
      collections.each do |collection|
        collection.update!(file_number)
      end
    end
  end
end
class FixfileNumberCollections
  ASSOCIATED_OBJECTS = FixFileNumberWizard::ASSOCIATIONS
  def self.get_collections(veteran)
    ASSOCIATED_OBJECTS.map do |klass|
      FixFileNumberWizard::Collection.new(klass, veteran.ssn)
    end
  end
end
