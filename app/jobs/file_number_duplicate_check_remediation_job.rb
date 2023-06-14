# frozen_string_literal: true

require "./lib/helpers/war_room.rb"
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
    bulk_decision_docs_with_error.map do |decision_document|
      vet = decision_document.veteran
      appeal = decision_document.appeal

      fail VeteranSSNAndFileNumberNoMatchError if vet.ssn != vet.file_number

      fail DuplicateVeteranFoundOutCodeError if duplicate_vet?(vet)

      # WarRoom::FileNumberNotFoundRemediationJob.new(appeal).perform
      FileNumberNotFoundRemediationJob.new(appeal).perform

      # rescue FileNumberMachesVetFileNumberError => error
      # rescue FileNumberIsNilError => error
      # rescue DuplicateVeteranFoundError => error
      # rescue NoAssociatedRecordsFoundForFileNumberError => error
    end
  end

  def bulk_decision_docs_with_error
    DecisionDocument.where("error LIKE ?", "%#{ERROR_TEXT}%")
  end

  def single_decision_doc_with_errors(ssn: nil, appeal: nil)
    if ssn.present?
      veteran = Veteran.find_by(ssn: ssn)
    elsif appeal.present?
      veteran = appeal.veteran
    end

    if veteran.ssn != veteran.file_number
      fail VeteranSSNAndFileNumberNoMatchError
    end

    WarRoom::FileNumberNotFoundRemediationJob.new.perform(vet)
  end

  def duplicate_vet?(veteran)
    WarRoom::OutcodeWithDuplicateVeteran.new.run_check_by_duplicate_veteran_file_number(veteran.file_number)
  end
end
