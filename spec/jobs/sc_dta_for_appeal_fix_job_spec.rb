# frozen_string_literal: true

describe ScDtaForAppealFixJob, :postgres do
  let(:sc_dta_for_appeal_error) { "Can't create a SC DTA for appeal" }
  let!(:veteran_file_number) { "111223333" }
  let!(:veteran_file_number_2) { "999999999" }

  # let!(:veteran) { create(:veteran, file_number: veteran_file_number) }
  let(:appeal) { create(:appeal, veteran_file_number: veteran_file_number) }
  let(:appeal_2) { create(:appeal, veteran_file_number: veteran_file_number_2) }
  let!(:decision_doc_with_error) do
    create(
      :decision_document,
      error: sc_dta_for_appeal_error,
      appeal: appeal
    )
  end

  let!(:decision_doc_with_error_2) do
    create(
      :decision_document,
      error: sc_dta_for_appeal_error,
      appeal: appeal_2
    )
  end

  before do
    create_list(:decision_document, 5)
  end

  subject { described_class.new }

  context "#sc_dta_for_appeal_fix" do
    context "when payee_code is nil" do
      before do
        decision_doc_with_error.appeal.claimant.update(payee_code: nil)
      end
      # we need to manipulate the claimant.type for these describes
      describe "claimant.type is VeteranClaimant" do
        it "updates payee_code to 00" do
          decision_doc_with_error_2.appeal.claimant.update(payee_code: nil)

          subject.sc_dta_for_appeal_fix
          expect(decision_doc_with_error.appeal.claimant.payee_code).to eq("00")
          expect(decision_doc_with_error_2.appeal.claimant.payee_code).to eq("00")
        end

        it "clears error column" do
          subject.sc_dta_for_appeal_fix
          expect(decision_doc_with_error.reload.error).to be_nil
        end
      end

      describe "claimant.type is DependentClaimant" do
        it "updates payee_code to 10" do
          decision_doc_with_error.appeal.claimant.update(type: "DependentClaimant")
          subject.sc_dta_for_appeal_fix
          expect(decision_doc_with_error.appeal.claimant.payee_code).to eq("10")
        end

        it "clears error column" do
          decision_doc_with_error.appeal.claimant.update(type: "DependentClaimant")
          subject.sc_dta_for_appeal_fix
          expect(decision_doc_with_error.reload.error).to be_nil
        end
      end
    end

    context "when payee_code is populated" do
      it "does not update payee_code" do
        expect(decision_doc_with_error.appeal.claimant.payee_code).to eq("00")
        subject.sc_dta_for_appeal_fix
        expect(decision_doc_with_error.appeal.claimant.payee_code).to eq("00")
      end
      it "does not clear error field" do
        subject.sc_dta_for_appeal_fix
        expect(decision_doc_with_error.error).to eq(sc_dta_for_appeal_error)
      end
    end
  end
end
