# frozen_string_literal: true

describe DtaScCreationFailedFixJob, :postgres do
  let(:dta_error) { "DTA SC creation failed" }
  let!(:veteran_file_number) { "111223333" }
  let!(:veteran) { create(:veteran, file_number: veteran_file_number) }

  let!(:hlr) { create(:higher_level_review, veteran_file_number: veteran_file_number, establishment_error: dta_error) }
  let!(:sc) { create(:supplemental_claim, veteran_file_number: veteran_file_number, decision_review_remanded: hlr) }

  context "#dta_sc_creation_failed_fix" do
    subject { described_class.new("higher_level_review", dta_error) }

    context "When SC has decision_review_remanded_id and decision_review_remanded_type" do
      it "clears the error field on related HLR" do
        subject.perform
        expect(hlr.reload.establishment_error).to be_nil
      end
    end

    context "When either decision_review_remanded_id or decision_review_remanded_type values are nil" do
      describe "when decision_review_remanded_id is nil" do
        it "does not clear error field on related HLR" do
          sc.update(decision_review_remanded_id: nil)
          subject.perform
          expect(hlr.reload.establishment_error).to eql(dta_error)
        end
      end

      describe "when decision_review_remanded_type is nil" do
        it "does not clear error field on related HLR" do
          sc.update(decision_review_remanded_type: nil)
          subject.perform
          expect(hlr.reload.establishment_error).to eql(dta_error)
        end
      end
    end
  end
end
