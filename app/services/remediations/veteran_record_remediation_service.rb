# frozen_string_literal: true

require_relative "../../../lib/helpers/fix_file_number_wizard"

class Remediations::VeteranRecordRemediationService
  ASSOCIATED_OBJECTS = FixFileNumberWizard::ASSOCIATIONS

  def initialize(before_fn, after_fn)
    @before_fn = before_fn
    @after_fn = after_fn
  end

  def remediate!
    # check for dup
    # if dup exists run fix_vet_records on
    # run dup_fix if @before_fn == @after_fn : fix_vet_records
    # Check for duplicates based on the file number
    real_v = Veteran.find_by_file_number(@after_fn)
    dups = Veteran.where(ssn: real_v.ssn).reject { |v| v.id == real_v.id }

    if dups.any?
      # If there are duplicates, run dup_fix on @after_fn
      dup_fix(@after_fn)
    else
      # Otherwise, fix veteran records normally
      fix_vet_records
    end
    # dup_fix(@after_fn) ? @before_fn == @after_fn : fix_vet_records
  end

  private

  def dup_fix(file_number)
    real_v = Veteran.find_by_file_number(file_number)
    dups = Veteran.where(ssn: real_v.ssn).reject { |v| v.id == real_v.id }
    duplicate_veterans_collections = dups.flat_map { |dup| grab_collections(dup.file_number) }
    update_records!(duplicate_veterans_collections, file_number)
    # may need to fix intakes with veteran id
    # destroy dup
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
