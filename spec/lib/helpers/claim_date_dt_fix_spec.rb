# frozen_string_literal: true

require "./lib/helpers/claim_date_dt_fix"

describe ClaimDateDtFix, :postres do
  let(:claim_date_dt_error) { "ClaimDateDt" }

  let!(:decision_doc_with_error) do
    create(
      :decision_document,
      error: claim_date_dt_error,
      processed_at: 7.days.ago,
      uploaded_to_vbms_at: 7.days.ago
    )
  end

  subject { described_class.new("decision_document", "ClaimDateDt") }

  let!(:expected_logs) do
    " #{Time.zone.now} ClaimDateDt::Log - Summary Report. Total number of Records with Errors: 0"
  end

  before do
    create_list(:decision_document, 5)
    create_list(:decision_document, 2, error: claim_date_dt_error, processed_at: 7.days.ago,
                                       uploaded_to_vbms_at: 7.days.ago)
  end

  context "when error, processed_at and uploaded_to_vbms_at are populated" do
    it "clears the error field" do
      expect(subject.decision_docs_with_errors.count).to eq(3)
      subject.perform

      # expect(subject.logs.last).to include(expected_logs)
      expect(decision_doc_with_error.reload.error).to be_nil
      expect(subject.decision_docs_with_errors.count).to eq(0)
    end
  end

  context "when either uploaded_to_vbms_at or processed_at are nil" do
    describe "when upladed_to_vbms_at is nil" do
      it "does not clear the error field" do
        decision_doc_with_error.update(uploaded_to_vbms_at: nil)

        expect(decision_doc_with_error.error).to eq("ClaimDateDt")

        subject.perform

        expect(decision_doc_with_error.reload.error).not_to be_nil
      end
    end

    describe "when processed_at is nil" do
      it "does not clear the error field" do
        decision_doc_with_error.update(processed_at: nil)
        expect(decision_doc_with_error.error).to eq("ClaimDateDt")

        subject.perform

        expect(decision_doc_with_error.reload.error).not_to be_nil
      end
    end
  end
end
