# frozen_string_literal: true

describe FileNumberDuplicateCheckRemediationJob, :postgres do
  ERROR_TEXT = "FILENUMBER does not exist"
  let!(:number) { "424200002" }
  let!(:number_2) { "999999999" }
  let!(:bgs_file_number_1) { "000979834" }
  let!(:bgs_file_number_2) { "999979834" }

  let!(:veteran) { create(:veteran, ssn: number, file_number: number) }
  let!(:veteran_2) { create(:veteran, ssn: number_2, file_number: number_2) }
  let!(:appeal) { create(:appeal, veteran_file_number: number) }
  let!(:appeal_2) { create(:appeal, veteran_file_number: veteran_2.file_number) }

  let!(:decision_document) { create(:decision_document, appeal_type: "Appeal", appeal_id: appeal.id, error: ERROR_TEXT) }
  let!(:decision_document_2) { create(:decision_document, appeal_type: "Appeal", appeal_id: appeal_2.id, error: ERROR_TEXT) }



  let!(:available_hearing_locations) { create(:available_hearing_locations, veteran_file_number: number_2) }
  let!(:bgs_power_of_attorney) { create(:bgs_power_of_attorney, file_number: number_2) }
  let!(:document) { create(:document, file_number: number_2) }
  let!(:end_product_establishment) { create(:end_product_establishment, veteran_file_number: number_2) }
  let!(:form8) { create(:default_form8, file_number: number_2) }
  let!(:higher_level_review) { create(:higher_level_review, veteran_file_number: number_2) }
  let!(:intake) { create(:intake, veteran_file_number: number_2) }
  let!(:ramp_election) { create(:ramp_election, veteran_file_number: number_2) }
  let!(:ramp_refiling) { RampRefiling.create(veteran_file_number: number_2) }
  let!(:supplemental_claim) { create(:supplemental_claim, veteran_file_number: number_2) }


  let!(:available_hearing_locations) { create(:available_hearing_locations, veteran_file_number: number) }
  let!(:bgs_power_of_attorney) { create(:bgs_power_of_attorney, file_number: number) }
  let!(:document) { create(:document, file_number: number) }
  let!(:end_product_establishment) { create(:end_product_establishment, veteran_file_number: number) }
  let!(:form8) { create(:default_form8, file_number: number) }
  let!(:higher_level_review) { create(:higher_level_review, veteran_file_number: number) }
  let!(:intake) { create(:intake, veteran_file_number: number) }
  let!(:ramp_election) { create(:ramp_election, veteran_file_number: number) }
  let!(:ramp_refiling) { RampRefiling.create(veteran_file_number: number) }
  let!(:supplemental_claim) { create(:supplemental_claim, veteran_file_number: number) }

  # let!(:number_2) { "524200005" }
  # let!(:bgs_file_number) { "500979835" }

  # let!(:veteran_2) { create(:veteran, ssn: number_2, file_number: number_2) }
  # let!(:appeal_2) { create(:appeal, veteran_file_number: number) }
  # let!(:decision_document_2) { create(:decision_document, appeal_type: "Appeal", appeal_id: appeal_2.id, error: ERROR_TEXT) }

  subject { FileNumberDuplicateCheckRemediationJob.new }

  before do
    allow_any_instance_of(FileNumberNotFoundRemediationJob).to receive(:upload_logs_to_s3).and_return("logs")
    allow_any_instance_of(FileNumberNotFoundRemediationJob).to receive(:fetch_file_number_from_bgs_service).and_return(bgs_file_number_1, bgs_file_number_2 )
  end

  context "decision document with errors" do
    before do
      create_list(:decision_document, 3)
    end

    it "fixes the FileNumberNotFoundError" do
      allow(subject)
        .to receive(:duplicate_vet?)
        .and_return(false)

      count = DecisionDocument.where("error LIKE ?", "%#{ERROR_TEXT}%").count

      expect(count).to eq(2)
      subject.perform

      decision_document.reload
      decision_document_2.reload
      after_fix_count = DecisionDocument.where("error LIKE ?", "%#{ERROR_TEXT}%").reload.count
      expect(veteran.reload.file_number).to eq(bgs_file_number_1)
      expect(decision_document.error).to eq(nil)
      expect(decision_document_2.error).to eq(nil)
      # expect(after_fix_count).to eq(0)
    end

    it 'fixes multiple records fileNumber error' do


      allow(subject)
      .to receive(:duplicate_vet?)
      .and_return(false)

    count = DecisionDocument.where("error LIKE ?", "%#{ERROR_TEXT}%").count

    expect(count).to eq(1)
    subject.perform

    decision_document.reload
    after_fix_count = DecisionDocument.where("error LIKE ?", "%#{ERROR_TEXT}%").reload.count
    expect(veteran.reload.file_number).to eq(bgs_file_number)
    expect(decision_document.error).to eq(nil)
    expect(after_fix_count).to eq(0)
    end

    it "throws an error if there is a duplicate veteran" do
      # allow(subject)
      #   .to receive(:duplicate_vet?)
      #   .and_return(true)
      # expect { subject.perform }.to raise_error(FileNumberDuplicateCheckRemediationJob::DuplicateVeteranFoundOutCodeError)
      expect { subject.perform }.to raise_error
    end

    context "when vet ssn does not match vet file_number" do
      it "throws an error" do
        veteran.update(ssn: "333112222")
        expect { subject.perform }.to raise_error(FileNumberDuplicateCheckRemediationJob::VeteranSSNAndFileNumberNoMatchError)
      end
    end
  end

  context "#single_decision_doc_with_errors" do
    describe "when ssn is passed in" do
      it "resolves filenumber error" do
        FileNumberDuplicateCheckRemediationJob.new.single_decision_doc_with_errors(ssn:veteran.ssn)

        expect(veteran.reload.file_number).to eq(bgs_file_number)
        binding.pry
      end
    end

  end
end
