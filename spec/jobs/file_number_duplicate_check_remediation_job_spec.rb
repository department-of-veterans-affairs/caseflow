# frozen_string_literal: true

# require './jobs/file_number_duplicate_check_remediation_job.rb'

# ********************** WORK IN PROGRESS DO NOT REVIEW****************************

describe FileNumberDuplicateCheckRemediationJob, :postgres do
  # let!(:number) { "424200002" }
  # let!(:bgs_file_number) { "000979834" }

  ERROR_TEXT = "FILENUMBER does not exist"
  # let!(:veteran) { create(:veteran, ssn: number, file_number: number) }
  let!(:number) { "424200002" }
  let!(:bgs_file_number) { "000979834" }

  let!(:veteran) { create(:veteran, ssn: number, file_number: number) }
  let!(:decision_document) { create(:decision_document, error: ERROR_TEXT) }
  subject { FileNumberDuplicateCheckRemediationJob.new }
  fixer { WarRoom::FileNumberNotFoundRemediationJob.new(veteran.appeal) }

  context "multiple decision documents with errors" do
    it "fixes the FileNumberNotFoundError" do
      #double
      fixer =  double(WarRoom::FileNumberNotFoundRemediationJob)
      allow(subject)
        .to receive(:duplicate_vet?)
        .and_return(false)

      allow(fixer)
        .to receive(:fetch_file_number_from_bgs_service)
        .and_return(bgs_file_number)

      subject.perform
      binding.pry
      expect(decision_document.error).to eq("")
    end

    it "throws an error if there is a dupulicate veteran" do
      allow(subject)
        .to receive(:duplicate_vet?)
        .and_return(true)
      expect { subject.perform }.to raise_error(FileNumberDuplicateCheckRemediationJob::DuplicateVeteranFoundOutCodeError)
    end
  end

  context "single decision" do
  end
end
