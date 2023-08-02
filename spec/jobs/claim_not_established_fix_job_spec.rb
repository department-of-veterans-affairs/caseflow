# frozen_string_literal: true

describe ClaimNotEstablishedFixJob, :postgres do
  let(:claim_not_established_error) { "Claim not established." }
  let!(:veteran_file_number) { "111223333" }
  let!(:veteran) { create(:veteran, file_number: veteran_file_number) }
  let(:appeal) { create(:appeal, veteran_file_number: veteran_file_number) }

  let!(:decision_doc_with_error) do
    create(
      :decision_document,
      error: claim_not_established_error,
      processed_at: 7.days.ago,
      uploaded_to_vbms_at: 7.days.ago,
      appeal: appeal
    )
  end

  let!(:epe) do
    create(
      :end_product_establishment,
      code: "030BGRNR",
      source: decision_doc_with_error,
      veteran_file_number: veteran_file_number,
      established_at: Time.zone.now
    )
  end

  context "#claim_not_established" do
    subject { described_class.new("decision_document", claim_not_established_error) }

    context "when code and established_at are present on epe" do
      it "clears the error field when epe code  is 030" do
        epe.update(code: "030")
        subject.perform

        expect(decision_doc_with_error.reload.error).to be_nil
      end

      it "clears the error field when epe code  is 040" do
        epe.update(code: "040")
        subject.perform

        expect(decision_doc_with_error.reload.error).to be_nil
      end

      it "clears the error field when epe code  is 930" do
        epe.update(code: "930")
        subject.perform

        expect(decision_doc_with_error.reload.error).to be_nil
      end

      it "clears the error field when epe code  is 682" do
        epe.update(code: "682")
        subject.perform

        expect(decision_doc_with_error.reload.error).to be_nil
      end
    end

    context "When either code or established_at are missing on epe" do
      describe "when code and established_at are nil" do
        it "does not clear error on decision_document" do
          epe.update(code: nil)
          epe.update(established_at: nil)
          subject.perform

          expect(decision_doc_with_error.reload.error).to eq(claim_not_established_error)
        end
      end
      describe "when code is nil" do
        it "does not clear error on decision_document" do
          epe.update(code: nil)
          subject.perform

          expect(decision_doc_with_error.reload.error).to eq(claim_not_established_error)
        end
      end

      describe "when established_at is nil" do
        it "does not clear error on decision_document" do
          epe.update(established_at: nil)
          subject.perform

          expect(decision_doc_with_error.reload.error).to eq(claim_not_established_error)
        end
      end
    end
  end
end
