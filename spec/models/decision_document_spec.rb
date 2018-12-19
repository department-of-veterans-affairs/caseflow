describe DecisionDocument do
  before do
    Timecop.freeze(Time.utc(2020, 1, 1, 19, 0, 0))
  end

  let(:decision_document) { create(:decision_document, file: file) }
  let(:file) { nil }

  context "#pdf_location" do
    subject { decision_document.pdf_location }

    it "should fetch file from s3 and return temporary location" do
      expect(Caseflow::Fakes::S3Service).to receive(:fetch_file)
      expect(subject).to eq File.join(Rails.root, "tmp", "pdfs", decision_document.appeal.external_id + ".pdf")
    end
  end

  context "#submit_for_processing!" do
    subject { decision_document.submit_for_processing! }

    context "when there is a file" do
      let(:file) { "JVBERi0xLjMNCiXi48/TDQoNCjEgMCBvYmoNCjw8DQovVHlwZSAvQ2F0YW" }

      it "caches the file" do
        expect(S3Service).to receive(:store_file).with("decisions/#{decision_document.appeal.external_id}.pdf", /PDF/)
        subject
        expect(decision_document.submitted_at).to eq(Time.zone.now + DecisionDocument::DECISION_OUTCODING_DELAY)
      end
    end

    context "when no file" do
      it "raises NoFileError" do
        expect { subject }.to raise_error(DecisionDocument::NoFileError)
        expect(decision_document.submitted_at).to be_nil
      end
    end
  end

  context "#process!" do
    subject { decision_document.process! }

    context "when processing was successful" do
      it "works" do
        expect(VBMSService).to receive(:upload_document_to_vbms).with(decision_document.appeal, decision_document)

        subject

        expect(decision_document.attempted_at).to eq(Time.zone.now)
        expect(decision_document.processed_at).to eq(Time.zone.now)
      end
    end

    context "when there was an error in processing" do
      before do
        allow(VBMSService).to receive(:upload_document_to_vbms).and_raise("Some VBMS error")
      end

      it "saves document as attempted but not processed and saves the error" do
        expect { subject }.to raise_error("Some VBMS error")

        expect(decision_document.attempted_at).to eq(Time.zone.now)
        expect(decision_document.processed_at).to be_nil
        expect(decision_document.error).to eq("Some VBMS error")
      end
    end
  end
end
