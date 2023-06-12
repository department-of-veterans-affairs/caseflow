# frozen_string_literal: true

describe FileNumberNotFoundRemediationJob, :postgres do

  let(:number) { "1234567890" }
  let(:bgs_file_number) { "9876543210" }
  let(:veteran) { create(:veteran, ssn: number, file_number: number) }
  let(:available_hearing_locations) { create(:available_hearing_locations, veteran_file_number: number) }
  let(:bgs_power_of_attorney) { create(:bgs_power_of_attorney, file_number: number) }
  let(:document) { create(:document, file_number: number) }
  let(:end_product_establishment) { create(:end_product_establishment, veteran_file_number: number) }
  let(:form8) { create(:form8, file_number: number) }
  let(:higher_level_review) { create(:higher_level_review, veteran_file_number: number) }
  let(:intake) { create(:intake, veteran_file_number: number) }
  let(:legacy_appeal) { create(:legacy_appeal, veteran_file_number: number) }
  let(:ramp_election) { create(:ramp_election, veteran_file_number: number) }
  let(:ramp_refiling) { create(:ramp_refiling, veteran_file_number: number) }
  let(:supplemental_claim) { create(:supplemental_claim, veteran_file_number: number) }

  subject { FileNumberNotFoundRemediationJob.new(veteran).perform }
  context "ama appeal" do
    context "when BGS file_number does not match veteran file_number" do

    end

    context "when job completes successfully" do
      it "updates the veteran file_number" do
        subject
        allow_any_instance_of(subject)
          .to receive(:fetch_file_number_from_bgs_service)
          .with(veteran.ssn)
          .and_return(bgs_file_number)


        expect(veteran.file_number).to eql(bgs_file_number)

      end
      it "updates associated objects" do
        allow(subject)
          .to receive(:fetch_file_number_from_bgs_service)
          .with(veteran.ssn)
          .and_return(bgs_file_number)

        subject

        expect(veteran.file_number).to eql(bgs_file_number)
        expect(available_hearing_locations.veteran_file_number).to eql(bgs_file_number)
        expect(end_product_establishment.veteran_file_number).to eql(bgs_file_number)
        expect(higher_level_review.veteran_file_number).to eql(bgs_file_number)
        expect(intake.veteran_file_number).to eql(bgs_file_number)
        expect(ramp_election.veteran_file_number).to eql(bgs_file_number)
        expect(ramp_refiling.veteran_file_number).to eql(bgs_file_number)
        expect(supplemental_claim.veteran_file_number).to eql(bgs_file_number)
        expect(bgs_power_of_attorney.file_number).to eql(bgs_file_number)
        expect(document.file_number).to eql(bgs_file_number)
        expect(form8.file_number).to eql(bgs_file_number)
      end
    end

    context "when job does not complete successfully" do
      it "rollsback everything"

    end

    context "when file vet file_number matches VBMS file_number" do
      it "throws an error"
      describe " when file number from vbms is nil" do
        it "throws an error"
      end
      describe "when veteran is found by file_number from vbms" do
        it "throws an error"
      end
    end
  end
end
