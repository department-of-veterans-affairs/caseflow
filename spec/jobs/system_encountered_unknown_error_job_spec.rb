# frozen_string_literal: true

describe SystemEncounteredUnknownErrorJob, :postgres do
  let(:system_encountered_unknown_error) { "The system has encountered an unknown error" }

  my_time = Time.zone.now

  let!(:decision_document) do
    create(
      :decision_document,
      error: system_encountered_unknown_error,
      processed_at: 7.days.ago,
      uploaded_to_vbms_at: 7.days.ago
    )
  end

  let!(:epe) do
    create(
      :end_product_establishment,
      source_id: decision_document.id,
      source_type: "DecisionDocument",
      established_at: 7.days.ago,
      reference_id: decision_document.id
    )
  end

  before do
    Timecop.freeze(Time.zone.now)
    create_list(
      :decision_document,
      3,
      error: system_encountered_unknown_error,
      processed_at: 7.days.ago,
      uploaded_to_vbms_at: 7.days.ago
    )
    create_list(
      :decision_document,
      1,
      error: nil,
      processed_at: 7.days.ago,
      uploaded_to_vbms_at: 7.days.ago
    )

    DecisionDocument.all.each do |decision_document|
      if !decision_document.end_product_establishments.empty?
        next
      else
        create(
          :end_product_establishment,
          source_id: decision_document.id,
          source_type: "DecisionDocument",
          established_at: 7.days.ago,
          reference_id: decision_document.id
        )
      end
    end
  end

  it_behaves_like "a Master Scheduler serializable object", SystemEncounteredUnknownErrorJob
  subject { described_class.new }

  context "When there are no decision documents with errors" do
    it "Does not process any decision docs" do
      decision_document.update!(error: nil)
      subject.perform

      expect(decision_document.error).to be_nil
    end
  end

  context "When the Decision Document is not valid" do
    it "logs the error and does not clear the error for the decision document" do
      decision_document.update!(processed_at: nil)
      subject.perform

      expect(decision_document.reload.error).to eq(system_encountered_unknown_error)
    end
  end

  context "when there are no EPE's for the decision document" do
    it "performs upload document to VBMS and clears error" do
      epe.destroy
      expect(ExternalApi::VBMSService).to receive(:upload_document_to_vbms)
      subject.perform

      expect(decision_document.reload.error).to be_nil
      expect(decision_document.reload.updated_at).to be_within(15.seconds).of(my_time)
    end
  end

  context "When there are one or more EPE's that belong to a decision document" do
    context "When the EPE's are all valid" do
      it "clears the error field" do
        expect(DecisionDocument.all.count).to eq(5)
        expect(subject.records_with_errors.count).to eq(4)
        subject.perform

        expect(subject.records_with_errors.count).to eq(0)
      end
    end
    context "When there is an invalid EPE" do
      it "logs the error and does not clear the error for the decision document" do
        expect(DecisionDocument.all.count).to eq(5)
        epe.update!(reference_id: nil)
        subject.perform

        expect(decision_document.reload.error).to eq(system_encountered_unknown_error)
        expect(subject.records_with_errors.count).to eq(1)
      end
    end
  end
end
