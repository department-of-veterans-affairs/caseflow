# frozen_string_literal: true

module WarRoom
  class FileNumberRemediationJob < CaseflowJob
    queue_with_priority :low_priority

    ERROR_TEXT = "FILENUMBER does not exist"

    def check_if_duplicate_veteran(_veteran)
      decision_doc_with_error.map do |decision_document|
        vet = decision_document.veteran
        return if duplicate_vet?(vet) # Eventaully call duplicateVetJob

        WarRoom::FileNumberNotFoundRemediationJob.new.decision_document_with_errors(decision_document)
      end
    end

    def decision_doc_with_error
      DecisionDocument.where("error LIKE ?", "%#{ERROR_TEXT}%")
    end

    def duplicate_vet?
      WarRoom::OutcodeWithDuplicateVeteran.new.run_check_by_duplicate_veteran_file_number(veteran.file_number)
      # Need to add other methods here too
      # Do we need to check

    end
  end
end
