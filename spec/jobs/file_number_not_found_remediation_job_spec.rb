# frozen_string_literal: true

describe FileNumberNotFoundRemediationJob, :postgres do
  let!(:number) { "424200002" }
  let!(:bgs_file_number) { "000979834" }

  let!(:veteran) { create(:veteran, ssn: number, file_number: number) }
  let!(:veteran_2) { create(:veteran, ssn: "999999999") }
  let!(:appeal) { create(:appeal, veteran_file_number: number) }
  let!(:appeal_2) { create(:appeal, veteran_file_number: veteran_2.file_number) }

  let!(:available_hearing_locations) { create(:available_hearing_locations, veteran_file_number: number) }
  let!(:bgs_power_of_attorney) { create(:bgs_power_of_attorney, file_number: number) }
  let!(:document) { create(:document, file_number: number) }
  let!(:end_product_establishment) { create(:end_product_establishment, veteran_file_number: number) }
  let!(:higher_level_review) { create(:higher_level_review, veteran_file_number: number) }
  let!(:intake) { create(:intake, veteran_file_number: number) }
  let!(:ramp_election) { create(:ramp_election, veteran_file_number: number) }
  let!(:ramp_refiling) { RampRefiling.create(veteran_file_number: number) }
  let!(:supplemental_claim) { create(:supplemental_claim, veteran_file_number: number) }
  let!(:form8) { create(:default_form8, file_number: number) }

  subject { FileNumberNotFoundRemediationJob.new(appeal) }

  before do
    allow(subject).to receive(:upload_logs_to_s3).with(anything).and_return("logs")
  end

  before do
    Timecop.freeze(Time.zone.now)
  end

  context "ama appeal" do
    context "when job completes successfully" do
      let!(:expected_logs) { "#{Time.zone.now} FILENUMBERERROR::Log Participant Id: #{veteran.participant_id}. @veteran File Number: #{bgs_file_number}. Status: File Number Updated." }

      before do
        allow(subject)
          .to receive(:fetch_file_number_from_bgs_service)
          .and_return(bgs_file_number)
      end

      it "updates the veteran file_number" do
        subject.perform
        veteran.reload
        expect(veteran.file_number).to eq(bgs_file_number)
      end

      it "updates the logs correctly" do
        subject.perform
        expect(subject.instance_variable_get("@logs")).to include(expected_logs)
      end

      it "updates associated objects" do
        subject.perform
        expect(veteran.reload.file_number).to eq(bgs_file_number)
        expect(available_hearing_locations.reload.veteran_file_number).to eq(bgs_file_number)
        expect(end_product_establishment.reload.veteran_file_number).to eq(bgs_file_number)
        expect(higher_level_review.reload.veteran_file_number).to eq(bgs_file_number)
        expect(intake.reload.veteran_file_number).to eq(bgs_file_number)
        expect(ramp_election.reload.veteran_file_number).to eq(bgs_file_number)
        expect(ramp_refiling.reload.veteran_file_number).to eq(bgs_file_number)
        expect(supplemental_claim.reload.veteran_file_number).to eq(bgs_file_number)
        expect(bgs_power_of_attorney.reload.file_number).to eq(bgs_file_number)
        expect(document.reload.file_number).to eq(bgs_file_number)
        # expect(form8.reload.vacols_id).to eq("123456789S") # Need to figure out why this one is different
      end
    end

    context "when job does not complete successfully" do
      it "rollsback everything" do
        allow(subject)
          .to receive(:fetch_file_number_from_bgs_service)
          .and_return("failure")

        subject.perform

        expect(veteran.reload.file_number).to eq(number)
        expect(available_hearing_locations.reload.veteran_file_number).to eq(number)
        expect(end_product_establishment.reload.veteran_file_number).to eq(number)
        expect(higher_level_review.reload.veteran_file_number).to eq(number)
        expect(intake.reload.veteran_file_number).to eq(number)
        expect(ramp_election.reload.veteran_file_number).to eq(number)
        expect(ramp_refiling.reload.veteran_file_number).to eq(number)
        expect(supplemental_claim.reload.veteran_file_number).to eq(number)
        expect(bgs_power_of_attorney.reload.file_number).to eq(number)
        expect(document.reload.file_number).to eq(number)
        # expect(form8.reload.file_number).to eq(bgs_file_number)
      end
    end

    context "when file vet file_number matches VBMS file_number" do
      it "throws Duplicate Veteran Found error" do
        allow(subject)
          .to receive(:fetch_file_number_from_bgs_service)
          .and_return(bgs_file_number)

        veteran.update(file_number: bgs_file_number)
        expect { subject.perform }.to raise_error(FileNumberNotFoundRemediationJob::DuplicateVeteranFoundError)
      end

      describe "when file number from vbms is nil" do
        it "throws File Number is nil error" do
          allow(subject)
            .to receive(:fetch_file_number_from_bgs_service)
            .and_return(nil)

          expect { subject.perform }.to raise_error(FileNumberNotFoundRemediationJob::FileNumberNotFoundError)
        end
      end

      describe "when veteran record is found by file_number from vbms" do
        it "throws a Fie Number matches veteran File number error" do
          bgs_file_number = "424200002"
          allow(subject)
            .to receive(:fetch_file_number_from_bgs_service)
            .and_return(bgs_file_number)
          expect { subject.perform }.to raise_error(FileNumberNotFoundRemediationJob::FileNumberMachesVetFileNumberError)
        end
      end
    end

    context "when no associations are found" do
      subject { FileNumberNotFoundRemediationJob.new(appeal_2) }
      it "throws an error" do
        allow(subject)
          .to receive(:fetch_file_number_from_bgs_service)
          .and_return(bgs_file_number)

        expect { subject.perform }.to raise_error(FileNumberNotFoundRemediationJob::NoAssociatedRecordsFoundForFileNumberError)
      end
    end
  end

  context "legacy appeal" do
    let!(:veteran_2) { create(:veteran, ssn: "999999998") }
    let!(:appeal_2) { create(:legacy_appeal, vacols_case: create(:case, bfcorlid: "399999998S")) }

    before do
      allow(subject)
        .to receive(:fetch_file_number_from_bgs_service)
        .and_return(bgs_file_number)
    end

    it "updates the veteran file_number" do
      allow(subject)
        .to receive(:fetch_file_number_from_bgs_service)
        .and_return(bgs_file_number)
      subject.perform
      veteran.reload
      expect(veteran.file_number).to eq(bgs_file_number)
    end

    it "updates associated objects" do
      subject.perform
      expect(veteran.reload.file_number).to eq(bgs_file_number)
      expect(available_hearing_locations.reload.veteran_file_number).to eq(bgs_file_number)
      expect(end_product_establishment.reload.veteran_file_number).to eq(bgs_file_number)
      expect(higher_level_review.reload.veteran_file_number).to eq(bgs_file_number)
      expect(intake.reload.veteran_file_number).to eq(bgs_file_number)
      expect(ramp_election.reload.veteran_file_number).to eq(bgs_file_number)
      expect(ramp_refiling.reload.veteran_file_number).to eq(bgs_file_number)
      expect(supplemental_claim.reload.veteran_file_number).to eq(bgs_file_number)
      expect(bgs_power_of_attorney.reload.file_number).to eq(bgs_file_number)
      expect(document.reload.file_number).to eq(bgs_file_number)
      # expect(form8.reload.file_number).to eq(bgs_file_number)
    end

    context "when job does not successfully complete" do
      it "rollsback everything" do
        allow(subject)
          .to receive(:fetch_file_number_from_bgs_service)
          .and_return("failure")

        subject.perform

        expect(veteran.reload.file_number).to eq(number)
        expect(available_hearing_locations.reload.veteran_file_number).to eq(number)
        expect(end_product_establishment.reload.veteran_file_number).to eq(number)
        expect(higher_level_review.reload.veteran_file_number).to eq(number)
        expect(intake.reload.veteran_file_number).to eq(number)
        expect(ramp_election.reload.veteran_file_number).to eq(number)
        expect(ramp_refiling.reload.veteran_file_number).to eq(number)
        expect(supplemental_claim.reload.veteran_file_number).to eq(number)
        expect(bgs_power_of_attorney.reload.file_number).to eq(number)
        expect(document.reload.file_number).to eq(number)
        # expect(form8.reload.file_number).to eq(bgs_file_number)
      end
    end

    context "when file vet file_number matches VBMS file_number" do
      it "throws Duplicate Veteran Found error" do
        veteran.update(file_number: bgs_file_number)
        expect { subject.perform }.to raise_error(FileNumberNotFoundRemediationJob::DuplicateVeteranFoundError)
      end

      describe " when file number from vbms is nil" do
        it "throws File Number is Nil error error" do
          allow(subject)
            .to receive(:fetch_file_number_from_bgs_service)
            .and_return(nil)

          expect { subject.perform }.to raise_error(FileNumberNotFoundRemediationJob::FileNumberNotFoundError)
        end
      end
      describe "when veteran is found by file_number from vbms" do
        it "throws a file number matches veteran file number error" do
          bgs_file_number = "424200002"
          allow(subject)
            .to receive(:fetch_file_number_from_bgs_service)
            .and_return(bgs_file_number)
          expect { subject.perform }.to raise_error(FileNumberNotFoundRemediationJob::FileNumberMachesVetFileNumberError)
        end
      end
    end
  end
end
