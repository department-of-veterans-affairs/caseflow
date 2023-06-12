# frozen_string_literal: true

require "helpers/file_number_not_found_fix.rb"

describe FileNumberNotFoundFix, :postgres do
  let!(:error_text) { "FILENUMBER does not exist" }

  before do
    allow(subject).to receive(:upload_logs_to_s3).with(anything).and_return("logs")
  end

  before do
    Timecop.freeze(Time.zone.now)
  end

  context "ama appeal" do
    let!(:error_text) { "FILENUMBER does not exist" }
    let!(:number) { "424200002" }
    let!(:number_2) { "788040001" }
    let!(:bgs_file_number) { "000979834" }
    let!(:bgs_file_number_2) { "555555555" }

    let!(:veteran) { create(:veteran, ssn: number, file_number: number) }
    let!(:veteran_2) { create(:veteran, ssn: number_2, file_number: number_2) }
    let!(:appeal) { create(:appeal, veteran_file_number: number) }
    let!(:appeal_2) { create(:appeal, veteran_file_number: number_2) }
    let!(:decision_document) { create(:decision_document, appeal_type: "Appeal", appeal_id: appeal.id, error: error_text) }
    let!(:decision_document_2) { create(:decision_document, appeal_type: "Appeal", appeal_id: appeal_2.id, error: error_text) }

    let!(:available_hearing_locations) { create(:available_hearing_locations, veteran_file_number: number) }
    let!(:available_hearing_locations_2) { create(:available_hearing_locations, veteran_file_number: number_2) }
    let!(:bgs_power_of_attorney) { create(:bgs_power_of_attorney, file_number: number) }
    let!(:bgs_power_of_attorney_2) { create(:bgs_power_of_attorney, file_number: number_2) }
    let!(:document) { create(:document, file_number: number) }
    let!(:end_product_establishment) { create(:end_product_establishment, veteran_file_number: number) }
    let!(:end_product_establishment_2) { create(:end_product_establishment, veteran_file_number: number_2) }
    let!(:higher_level_review) { create(:higher_level_review, veteran_file_number: number) }
    let!(:intake) { create(:intake, veteran_file_number: number) }
    let!(:ramp_election) { create(:ramp_election, veteran_file_number: number) }
    let!(:ramp_refiling) { RampRefiling.create(veteran_file_number: number) }
    let!(:supplemental_claim) { create(:supplemental_claim, veteran_file_number: number) }

    context "#fix_multiple_records" do
      subject { FileNumberNotFoundFix.new }

      context "when job completes successfully" do
        let!(:expected_logs) { "#{Time.zone.now} FILENUMBERERROR::Log Participant Id: 788690002.veteranFile Number: 555555555. Status: File Number Updated." }

        before do
          allow(subject)
            .to receive(:fetch_file_number_from_bgs_service)
            .and_return(bgs_file_number, bgs_file_number_2)
        end

        it "updates the veteran file_number" do
          subject.fix_multiple_records

          expect(veteran.reload.file_number).to eq(bgs_file_number)
          expect(veteran_2.reload.file_number).to eq(bgs_file_number_2)
        end

        it "updates the logs correctly" do
          subject.fix_multiple_records
          expect(subject.fix_multiple_records.instance_variable_get("@logs")).to include(expected_logs)
        end

        it "updates associated objects" do
          subject.fix_multiple_records
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
        end
      end
      context "when job does not complete successfully" do
        it "rollsback everything" do
          allow(subject)
            .to receive(:fetch_file_number_from_bgs_service)
            .and_return(nil)

          subject.fix_multiple_records

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
        end
      end

      context "when file vet file_number matches VBMS file_number" do
        describe "when file number from vbms = veteran_file_number" do
          it "does not update the file_number" do
            allow(subject)
              .to receive(:fetch_file_number_from_bgs_service)
              .and_return(number)
            subject.fix_multiple_records
            expect(veteran.reload.file_number).to eq(number)
          end
        end

        describe "when file number from vbms is nil" do
          it "does not update the file_number" do
            allow(subject)
              .to receive(:fetch_file_number_from_bgs_service)
              .and_return(nil)
            subject.fix_multiple_records
            expect(veteran.reload.file_number).to eq(number)
          end
        end
      end
    end

    context "#single_record_fix" do
      subject { FileNumberNotFoundFix.new }

      context "when job completes successfully" do
        let!(:expected_logs) { "#{Time.zone.now} FILENUMBERERROR::Log Participant Id: 788690002.veteranFile Number: 555555555. Status: File Number Updated." }

        before do
          allow(subject)
            .to receive(:fetch_file_number_from_bgs_service)
            .and_return(bgs_file_number, bgs_file_number_2)
        end

        it "updates the veteran file_number" do
          subject.single_record_fix(appeal)
          expect(veteran.reload.file_number).to eq(bgs_file_number)
        end

        it "updates the logs correctly" do
          subject.single_record_fix(appeal)
          expect(subject.instance_variable_get("@logs")).to include(expected_logs)
        end

        it "updates associated objects" do
          subject.single_record_fix(appeal)
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
        end
      end
      context "when job does not complete successfully" do
        it "rollsback everything" do
          allow(subject)
            .to receive(:fetch_file_number_from_bgs_service)
            .and_return(nil)

          subject.single_record_fix(appeal)

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
        end
      end

      context "when file vet file_number matches VBMS file_number" do
        describe "when file number from vbms = veteran_file_number" do
          it "does not update the file_number" do
            allow(subject)
              .to receive(:fetch_file_number_from_bgs_service)
              .and_return(number)
            subject.single_record_fix(appeal)
            expect(veteran.reload.file_number).to eq(number)
          end
        end

        describe "when file number from vbms is nil" do
          it "does not update the file_number" do
            allow(subject)
              .to receive(:fetch_file_number_from_bgs_service)
              .and_return(nil)
            subject.single_record_fix(appeal)
            expect(veteran.reload.file_number).to eq(number)
          end
        end
      end
    end
  end

  context "legacy appeal" do
    let!(:bgs_file_number) { "000979834S" }
    let!(:veteran_2) { create(:veteran, ssn: "343434349") }
    let!(:appeal_2) { create(:legacy_appeal, vbms_id: "343434349", vacols_case: create(:case, bfcorlid: "399999998S")) }
    let!(:form8) { create(:default_form8, file_number: "343434349S") }
    let!(:decision_document) { create(:decision_document, appeal_type: "LegacyAppeal", appeal_id: appeal_2.id, error: error_text) }

    subject { FileNumberNotFoundFix.new }

    before do
      allow(subject)
        .to receive(:fetch_file_number_from_bgs_service)
        .and_return(bgs_file_number)
    end

    it "updates the veteran file_number" do
      allow(subject)
        .to receive(:fetch_file_number_from_bgs_service)
        .and_return(bgs_file_number)

      allow(FixfileNumberCollections)
        .to receive(:get_collections)
        .with(veteran_2)
        .and_return([FixFileNumberWizard::Collection.new(Form8, veteran_2.ssn)])
      subject.fix_multiple_records
      veteran_2.reload
      expect(veteran_2.file_number).to eq(bgs_file_number)
      expect(form8.reload.file_number).to eq(bgs_file_number)
    end
  end
end
