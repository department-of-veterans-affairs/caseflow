# frozen_string_literal: true

describe UploadTokenFixJob, :postres do
  let!(:error_text) { "A problem has been detected with the upload token provided" }
  let!(:file_number) { "123454321" }

  let!(:vet) do
    create(
      :veteran,
      file_number: file_number
    )
  end

  let!(:appeal) do
    create(
      :appeal,
      veteran_file_number: file_number
    )
  end

  let!(:legacy_appeal) do
    create(
      :legacy_appeal,
      vbms_id: "#{file_number}S"
    )
  end

  let!(:decision_doc_with_error) do
    create(
      :decision_document,
      appeal_id: appeal.id,
      appeal_type: "Appeal",
      error: error_text
    )
  end

  let!(:legacy_appeal_decision_doc) do
    create(
      :decision_document,
      appeal_id: legacy_appeal.id,
      appeal_type: "LegacyAppeal",
      error: error_text
    )
  end

  let!(:epe) do
    create(
      :end_product_establishment,
      veteran_file_number: file_number,
      source_type: "DecisionDocument",
      source_id: decision_doc_with_error.id,
      established_at: Time.zone.now
    )
  end

  let!(:epe_2) do
    create(
      :end_product_establishment,
      veteran_file_number: file_number,
      source_type: "DecisionDocument",
      source_id: decision_doc_with_error.id,
      established_at: nil
    )
  end

  let!(:legacy_epe) do
    create(
      :end_product_establishment,
      veteran_file_number: file_number,
      source_type: "DecisionDocument",
      source_id: legacy_appeal_decision_doc.id,
      established_at: nil
    )
  end

  it_behaves_like "a Master Scheduler serializable object", UploadTokenFixJob

  subject { described_class.new }

  describe "records_with_errors returns with one or more decision documents" do
    context "when the decision document's EndProductEstablishments have all established in VBMS" do
      it "clears the error on the decision document" do
        epe_2.update(established_at: Time.zone.now)
        legacy_epe.update(established_at: Time.zone.now)

        subject.perform
        expect(decision_doc_with_error.reload.error).to be_nil
        expect(legacy_appeal_decision_doc.reload.error).to be_nil
      end
    end

    context "when a 'BVA Decision' document is found and it is present in VBMS" do
      it "clears the error on the decision document" do
        allow(subject).to receive(:fetch_bva_decisions).and_return([1, 2])
        allow(subject).to receive(:document_present_in_vbms?).and_return(true)

        subject.perform
        expect(decision_doc_with_error.reload.error).to be_nil
        expect(legacy_appeal_decision_doc.reload.error).to be_nil
      end
    end

    context "when a 'BVA Decision' document is found and it is not present in VBMS" do
      it "uploads the document to VBMS and clears the error on the decision document" do
        allow(subject).to receive(:fetch_bva_decisions).and_return([1, 2])
        allow(subject).to receive(:document_present_in_vbms?).and_return(false)
        class_double(ExternalApi::VBMSService, upload_document_to_vbms: true).as_stubbed_const

        expect(ExternalApi::VBMSService).to receive(:upload_document_to_vbms).twice
        subject.perform
        expect(decision_doc_with_error.reload.error).to be_nil
        expect(legacy_appeal_decision_doc.reload.error).to be_nil
      end
    end

    context "when a 'BVA Decision' document is not found" do
      it "uploads the document to VBMS and clears the error on the decision document" do
        allow(subject).to receive(:fetch_bva_decisions).and_return([])
        class_double(ExternalApi::VBMSService, upload_document_to_vbms: true).as_stubbed_const

        expect(ExternalApi::VBMSService).to receive(:upload_document_to_vbms).twice
        subject.perform
        expect(decision_doc_with_error.reload.error).to be_nil
        expect(legacy_appeal_decision_doc.reload.error).to be_nil
      end
    end
  end

  describe "records_with_errors returns empty" do
    context "when no errors are detected" do
      it "does not attempt to process decision documents" do
        decision_doc_with_error.update!(error: nil)
        legacy_appeal_decision_doc.update!(error: nil)

        expect(subject.records_with_errors).not_to receive(:each)
        subject.perform
      end
    end
  end
end
