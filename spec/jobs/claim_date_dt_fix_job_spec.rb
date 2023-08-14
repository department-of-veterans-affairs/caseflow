# frozen_string_literal: true

describe ClaimDateDtFixJob, :postres do
  let(:claim_date_dt_error) { "ClaimDateDt" }

  let!(:decision_doc_with_error) do
    create(
      :decision_document,
      error: claim_date_dt_error,
      processed_at: 7.days.ago,
      uploaded_to_vbms_at: 7.days.ago
    )
  end

# lets wrap all calls to the stuck job reporter with a stub and we can eliminate this before block
  # before do
  #   allow_any_instance_of(StuckJobReportService).to receive(:upload_logs_to_s3)
  # end


  # let(:stuck_job_service) { instance_double("StuckJobService") }

  # before do
  #   allow(stuck_job_service).to receive(:upload_logs_to_s3) { stuck_job_service }
  # end

  # policy = instance_double(WithdrawnDecisionReviewPolicy)
  # allow(WithdrawnDecisionReviewPolicy).to receive(:new).with(caseflow_appeal).and_return policy
  # allow(policy).to receive(:satisfied?).and_return true


# let(:blah) { instance_double(StuckJobReportService) }
 blah =  instance_double(StuckJobReporervice)


    before  do

      allow(StuckJobReportService).to receive(:new).and_return(blah)
      allow(blah).to receive(:upload_logs_to_s3)
      # expect(StuckJobService).to receive(:upload_logs_to_s3).and_return("blah")
    end





    # policy = instance_double(WithdrawnDecisionReviewPolicy)
    # allow(WithdrawnDecisionReviewPolicy).to receive(:new).with(caseflow_appeal).and_return policy
    # allow(policy).to receive(:satisfied?).and_return true













  subject { described_class.new("decision_document", "ClaimDateDt") }

  before do
    create_list(:decision_document, 5)
    create_list(:decision_document, 2, error: claim_date_dt_error, processed_at: 7.days.ago,
                                       uploaded_to_vbms_at: 7.days.ago)
  end

  context "when error, processed_at and uploaded_to_vbms_at are populated" do
    it "clears the error field" do
      expect(subject.decision_docs_with_errors.count).to eq(3)
      subject.perform

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
