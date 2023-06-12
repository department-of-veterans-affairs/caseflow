# frozen_string_literal: true

module WarRoom
  class FileNumberRemediationJob < CaseflowJob
    class DuplicateVeteranFoundOutCodeError < StandardError; end
    class VeteranSSNAndFileNumberNoMatchError < StandardError; end

    queue_with_priority :low_priority
    ERROR_TEXT = "FILENUMBER does not exist"

    attr_reader :veteran

    def initialize(veteran)
      @veteran = veteran

    end

    def check_if_duplicate_veteran
      bulk_decision_docs_with_error.map do |decision_document|
        vet = decision_document.veteran
        fail DuplicateVeteranFoundOutCodeError if duplicate_vet?(vet) # Eventaully call duplicateVetJob

        WarRoom::FileNumberNotFoundRemediationJob.new.perform(vet)
      end
    end

    def bulk_decision_docs_with_error
      DecisionDocument.where("error LIKE ?", "%#{ERROR_TEXT}%")
    end

    def single_decision_doc_with_errors(ssn: nil, appeal:nil)
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

      # Need to add other methods here too
      # Do we need to check

    end
  end
end



# DecisionDocument.where("error LIKE ?", "%FILENUMBER does not exist%")

# notes
# x = dd.error.split(", ")[4]
# pass x into regex \d+

# BGSService.new.fetch_file_number_by_ssn(ssn)
