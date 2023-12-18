# frozen_string_literal: true

describe DtaScCreationFailedFixJob, :postgres do
  let(:dta_error) { "DTA SC creation failed" }
  let!(:veteran_file_number) { "111223333" }
  let!(:veteran) { create(:veteran, file_number: veteran_file_number) }

  let!(:hlr) { create(:higher_level_review, veteran_file_number: veteran_file_number, establishment_error: dta_error) }
  let!(:sc) { create(:supplemental_claim, veteran_file_number: veteran_file_number, decision_review_remanded: hlr) }
  let!(:appeal) { create(:appeal, establishment_error: dta_error, veteran: veteran) }
  let!(:claimant) { create(:claimant, decision_review_id: appeal.id, decision_review_type: "Appeal") }

  # it_behaves_like "a Master Scheduler serializable object", DtaScCreationFailedFixJob

  subject { described_class.new }
  context "#dta_sc_creation_failed_fix" do

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

    context "When the appeal is established and the claimant has a payee code" do
      it "clears the error on the appeal" do
        subject.perform
        expect(appeal.reload.establishment_error).to be_nil
      end
    end

    context "When the appeal is established, but the payee_code is nil" do
      it "updates the payee_code and clears the error" do
        appeal.claimant.update(payee_code: nil)
        subject.perform
        expect(appeal.reload.establishment_error).to be_nil
        expect(appeal.reload.claimant.payee_code).to eq("00")
      end

      describe "when the claimant_type is a DependentClaimant" do
        it "updates the payee_code to 10 and clears the error" do
          appeal.claimant.update(type: "DependentClaimant")
          subject.perform
          expect(appeal.reload.establishment_error).to be_nil
          expect(appeal.reload.claimant.payee_code).to eq("10")
        end
      end
    end

    context "When the appeal is not established" do
      it "does not clear the error" do
        appeal.update(established_at: nil)
        subject.perform
        expect(appeal.reload.establishment_error).to eq(dta_error)
      end
    end
  end
end
