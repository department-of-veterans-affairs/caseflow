# frozen_string_literal: true

# require "./../../jobs/file_number_not_found_remediation_job.rb"
# require "./spec/jobs/file_number_not_found_remediation_job_spec.rb"
# spec/jobs/file_number_duplicate_check_remediation_job_spec.rb
# require "../../../app/jobs/file_number_not_found_remediation_job.rb"

describe FileNumberDuplicateCheckRemediationJob, :postgres do
  ERROR_TEXT = "FILENUMBER does not exist"
  let!(:number) { "424200002" }
  let!(:bgs_file_number) { "000979834" }

  let!(:veteran) { create(:veteran, ssn: number, file_number: number) }
  let!(:appeal) { create(:appeal, veteran_file_number: number) }
  let!(:decision_document) { create(:decision_document, appeal_type: "Appeal", appeal_id: appeal.id, error: ERROR_TEXT) }

  # let!(:number_2) { "524200005" }
  # let!(:bgs_file_number) { "500979835" }

  # let!(:veteran_2) { create(:veteran, ssn: number_2, file_number: number_2) }
  # let!(:appeal_2) { create(:appeal, veteran_file_number: number) }
  # let!(:decision_document_2) { create(:decision_document, appeal_type: "Appeal", appeal_id: appeal_2.id, error: ERROR_TEXT) }

  subject { FileNumberDuplicateCheckRemediationJob.new }
  # let!(:fixer) { double(FileNumberNotFoundRemediationJob)}
  let!(:fixer) { double(WarRoom::FileNumberNotFoundRemediationJob.new(appeal)) }

  # before do
  #   allow(WarRoom::FileNumberNotFoundRemediationJob.new)
  #   .to receive(:fetch_file_number_from_bgs_service).with(anything)
  #   .and_return(bgs_file_number)
  # end
  before do


  end

  context "decision document with errors" do
    before do
      create_list(:decision_document, 3)
    end

    it "fixes the FileNumberNotFoundError" do
      allow(subject)
        .to receive(:duplicate_vet?)
        .and_return(false)
        file_path = "string"
        # allow_any_instance_of(FileNumberNotFoundRemediationJob).to receive(:new).with(appeal).and_return(veteran)
      allow_any_instance_of(FileNumberNotFoundRemediationJob.perform_now(appeal)).to receive(:upload_to_s3).with(anything)

      subject.perform
      expect(veteran.reload.file_number).to eq(bgs_file_number)
      expect(veteran2.reload.file_number).to eq(bgs_file_number)
    end

    it "throws an error if there is a duplicate veteran" do
      allow(subject)
        .to receive(:duplicate_vet?)
        .and_return(true)
      expect { subject.perform }.to raise_error(FileNumberDuplicateCheckRemediationJob::DuplicateVeteranFoundOutCodeError)
    end

    context "when vet ssn does not match vet file_number" do
      it "throws an error" do
        veteran.update(ssn: "333112222")
        expect { subject.perform }.to raise_error(FileNumberDuplicateCheckRemediationJob::VeteranSSNAndFileNumberNoMatchError)
      end
    end
  end
end
