# frozen_string_literal: true

require "./lib/helpers/war_room.rb"
require "./lib/helpers/duplicate_veteran_checker.rb"
# require "./file_number_not_found_remediation_job.rb"

class FileNumberDuplicateCheckRemediationJob < CaseflowJob
  class DuplicateVeteranFoundOutCodeError < StandardError; end
  class VeteranSSNAndFileNumberNoMatchError < StandardError; end

  queue_with_priority :low_priority
  ERROR_TEXT = "FILENUMBER does not exist"

  attr_reader :veteran

  def initialize
    @veteran = veteran
    @logs = ["VBMS::FileNumberDuplicateCheckRemediationJob Remediation Log"]
  end

  def perform
    check_if_duplicate_veteran
  end

  def check_if_duplicate_veteran
    # binding.pry
    bulk_decision_docs_with_error.map do |decision_document|
      # binding.pry
      vet = decision_document.veteran
      appeal = decision_document.appeal
      # binding.pry
      fail VeteranSSNAndFileNumberNoMatchError if vet.ssn != vet.file_number

      fail DuplicateVeteranFoundOutCodeError if duplicate_vet?(vet)
      # binding.pry
      FileNumberNotFoundRemediationJob.new(appeal).perform
# binding.pry
      decision_document.update(error: nil)

      rescue FileNumberNotFoundRemediationJob::FileNumberMachesVetFileNumberError => error
      rescue FileNumberNotFoundRemediationJob::FileNumberIsNilError => error
      rescue FileNumberNotFoundRemediationJob::DuplicateVeteranFoundError => error
      rescue FileNumberNotFoundRemediationJob::NoAssociatedRecordsFoundForFileNumberError => error
    end
  end

  def bulk_decision_docs_with_error
    DecisionDocument.where("error LIKE ?", "%#{ERROR_TEXT}%")
  end

  def duplicate_vet?(veteran)
    WarRoom::OutcodeWithDuplicateVeteran.new.run_check_by_duplicate_veteran_file_number(veteran.file_number) # need to hit this hard in actual testing
  end
end
