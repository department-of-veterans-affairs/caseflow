# frozen_string_literal: true

require "helpers/duplicate_veteran_fixer"
require "./spec/lib/helpers/shared/veterans_context"

# Tests it fixes veteran duplication
RSpec.feature DuplicateVeteranFixer do
  include_context "veterans"

  context "run_remediation fixes veteran records duplication" do
    describe "#run_remediation" do
      describe "Success" do
        before do
          allow(duplicate_vet_fixer).to receive(:correct_file_number_by_ssn).and_return(bgs)
          allow(duplicate_vet_fixer).to receive(:duplicate_veterans).and_return([dup_veteran1, dup_veteran2])
        end

        it "updates relations to correct file number" do
          expect(Appeal.where(veteran_file_number: dup_pair_vet_number1).count).to eq(2)
          expect(Appeal.where(veteran_file_number: dup_pair_vet_number2).count).to eq(1)
          expect(LegacyAppeal.where(vbms_id: v1_vbms_id).count).to eq(1)
          expect(LegacyAppeal.where(vbms_id: v2_vbms_id).count).to eq(0)
          expect(BgsPowerOfAttorney.where(file_number: dup_pair_vet_number1).count).to eq(1)
          expect(BgsPowerOfAttorney.where(file_number: dup_pair_vet_number2).count).to eq(0)
          expect(Document.where(file_number: dup_pair_vet_number1).count).to eq(3)
          expect(Document.where(file_number: dup_pair_vet_number2).count).to eq(1)

          duplicate_vet_fixer.run_remediation

          expect(Appeal.where(veteran_file_number: dup_pair_vet_number2).count).to eq(3)
          expect(LegacyAppeal.where(vbms_id: v2_vbms_id).count).to eq(1)
          expect(Document.where(file_number: dup_pair_vet_number2).count).to eq(4)
          expect(EndProductEstablishment.where(veteran_file_number: dup_pair_vet_number2).count).to eq(1)
          expect(SupplementalClaim.where(veteran_file_number: dup_pair_vet_number2).count).to eq(2)
        end

        it "deletes extra record" do
          expect(Veteran.exists?(dup_veteran1.id)).to be true
          duplicate_vet_fixer.run_remediation
          expect(Veteran.exists?(dup_veteran1.id)).to be false
        end
      end

      describe "Failure handling" do
        xit "file number from bgs doesn't much correct veteran record" do
          allow(duplicate_vet_fixer).to receive(:valid_file_number?).and_return(false)
          expect(Rails.logger).to receive(:error).with("File number from BGS does not match correct veteran record.")

          duplicate_vet_fixer.run_remediation
        end

        it "Logs error if fails to delete veteran because there are remaining relations" do
          allow(duplicate_vet_fixer).to receive(:remaining_duplicates?).and_return(true)
          allow(duplicate_vet_fixer).to receive(:correct_file_number_by_ssn).and_return(bgs)
          expect(Rails.logger).to receive(:error)
            .with(match(/Duplicate veteran still has associated records. Can not delete until resolved./))

          duplicate_vet_fixer.run_remediation
        end

        it "It logs when no vets match duplicate file number" do
          allow(duplicate_vet_fixer).to receive(:correct_file_number_by_ssn).and_return(bgs)
          Veteran.find_by(file_number: dup_pair_vet_number1).update(file_number: ("a".."z").to_a.sample(8).join)
          Veteran.find_by(file_number: dup_pair_vet_number2).update(file_number: ("a".."z").to_a.sample(8).join)

          expect(Rails.logger).to receive(:error).with("No vets found with this file number.")

          duplicate_vet_fixer.run_remediation
        end

        it "It logs when there are more than two veterans with file number" do
          allow(duplicate_vet_fixer).to receive(:vets_count).and_return(2)
          expect(Rails.logger).to receive(:error).with("More than one duplicate veteran file number exists.")

          duplicate_vet_fixer.run_remediation
        end

        describe "validate_dup_vet logs errors" do
          before do
            allow(duplicate_vet_fixer).to receive(:correct_file_number_by_ssn).and_return(bgs)
          end

          it "Both veterans have the same file_number or No file_number on the correct veteran." do
            allow(duplicate_vet_fixer).to receive(:same_or_no_file_number).and_return(true)

            expect(Rails.logger).to receive(:error)
              .with("Both veterans have the same file_number or No file_number on the correct veteran.")

            duplicate_vet_fixer.run_remediation
          end

          it "Neither veteran has a ssn and a ssn is needed to check the BGS file number." do
            allow(duplicate_vet_fixer).to receive(:ssn_empty?).and_return(true)

            expect(Rails.logger).to receive(:error)
              .with("Neither veteran has a ssn and a ssn is needed to check the BGS file number.")

            duplicate_vet_fixer.run_remediation
          end

          it "Veterans do not have the same ssn and a correct ssn needs to be chosen." do
            allow(duplicate_vet_fixer).to receive(:same_ssn?).and_return(true)

            expect(Rails.logger).to receive(:error)
              .with("Veterans do not have the same ssn and a correct ssn needs to be chosen.")

            duplicate_vet_fixer.run_remediation
          end
        end

        xdescribe "pair_is_duplicate? logs errors" do
          before do
            allow(duplicate_vet_fixer).to receive(:correct_file_number_by_ssn).and_return(bgs)
          end

          it "No duplicate veteran found." do
            # TODO: add expectations
          end
          it "More than two veterans found" do
            # TODO: add expectations
          end
        end
      end
    end
  end
end
