# frozen_string_literal: true

describe SystemEncounteredUnknownErrorJob, :postgres do
  let(:system_encountered_unknown_error) { "The system has encountered an unknown error" }
  let(:file_number) { "123456789" }
  let(:appeal) do
    create(
      :appeal,
      veteran_file_number: file_number
    )
  end

  subject { described_class.new }

  context "When there are no decision documents with errors" do
    let!(:decision_document) do
      create(
        :decision_document,
        error: nil,
        processed_at: 7.days.ago,
        uploaded_to_vbms_at: 7.days.ago,
        appeal_id: appeal.id
      )
    end

    let!(:epe) do
      create(
        :end_product_establishment,
        source_id: decision_document.id,
        source_type: "DecisionDocument",
        established_at: nil,
        reference_id: nil
      )
    end

    it "Does not process any decision docs" do
      subject.perform
      expect(decision_document.error).to be_nil
    end
  end

  context "when there is no EPE for the decision document" do
    let!(:decision_document) do
      create(
        :decision_document,
        error: system_encountered_unknown_error,
        processed_at: 7.days.ago,
        uploaded_to_vbms_at: 7.days.ago,
        appeal_id: appeal.id
      )
    end

    let!(:epe) do
      create(
        :end_product_establishment,
        source_id: decision_document.id,
        source_type: "DecisionDocument",
        established_at: nil,
        reference_id: nil
      )
    end

    it "performs upload document to VBMS and clears error" do
      epe.destroy
      expect(ExternalApi::VBMSService).to receive(:upload_document_to_vbms)

      subject.perform
      expect(decision_document.reload.error).to be_nil
    end
  end

  context "When there are one or more EPE's that belong to a decision document" do
    let!(:decision_doc_with_error) do
      create(
        :decision_document,
        error: system_encountered_unknown_error,
        processed_at: 7.days.ago,
        uploaded_to_vbms_at: 7.days.ago,
        appeal_id: appeal.id
      )
    end

    let!(:epe) do
      create(
        :end_product_establishment,
        source_id: decision_doc_with_error.id,
        source_type: "DecisionDocument",
        established_at: 7.days.ago
      )
    end

    it "clears the error field" do
      expect(subject.decision_docs_with_errors.count).to eq(1)

      subject.perform

      expect(subject.decision_docs_with_errors.count).to eq(0)
    end
  end
end
