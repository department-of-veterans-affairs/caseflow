# frozen_string_literal: true

describe ClaimDateInvalidRemediationJob, :postgres do
  subject { ClaimDateInvalidRemediationJob.new }
  let!(:decision_doc_with_error) do
    create(:decision_document, error: "ClaimDateDt", processed_at: 7.days.ago, uploaded_to_vbms_at: 7.days.ago)
  end
  before do
    Timecop.freeze(Time.zone.now)
    allow(subject).to receive(:upload_logs_to_s3).with(anything).and_return("logs")
  end
  let(:expected_logs) do
    "\n #{Time.zone.now} ClaimDateInvalidRemediationJob::Log - Found 1 Decision Document(s) with errors"
  end

  context "when error, processed_at and uploaded_to_vbms_at are populated" do
    it "clears the error field" do
      expect(decision_doc_with_error.error).to eq("ClaimDateDt")
      subject.resolve_single_decision_document(decision_doc_with_error)
      expect(decision_doc_with_error.error).to be_nil
    end
  end

  it "updates the logs correctly" do
    subject.perform
    expect(subject.instance_variable_get("@logs")).to include(expected_logs)
  end

  context "when not all fields are populated" do
    describe "when processed_at field is nil" do
      it "does not update error field" do
        decision_doc_with_error.update(processed_at: nil)
        subject.perform
        expect(decision_doc_with_error.error).to eq("ClaimDateDt")
      end
    end

    describe "when uploaded_to_vbms_at field is nil" do
      it "does not update error field" do
        decision_doc_with_error.update(uploaded_to_vbms_at: nil)
        subject.perform
        expect(decision_doc_with_error.error).to eq("ClaimDateDt")
      end
    end
  end

  context "when faced with multiple decision documents" do
    it "filters out the decision documents with nil in error column" do
      create_list(:decision_document, 5)
      create_list(:decision_document, 2, error: "ClaimDateDt", processed_at: 7.days.ago,
                                         uploaded_to_vbms_at: 7.days.ago)

      expect(subject.retrieve_decision_docs_with_errors.length).to eq(3)
      subject.perform
      expect(subject.retrieve_decision_docs_with_errors.length).to eq(0)
    end
  end
end
