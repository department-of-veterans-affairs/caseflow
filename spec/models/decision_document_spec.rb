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
    before { FeatureToggle.enable!(:decision_document_upload) }
    after { FeatureToggle.disable!(:decision_document_upload) }

    let(:expected_path) { "decisions/#{decision_document.appeal.external_id}.pdf" }

    context "when there is a file" do
      let(:file) { "JVBERi0xLjMNCiXi48/TDQoNCjEgMCBvYmoNCjw8DQovVHlwZSAvQ2F0YW" }

      it "caches the file" do
        expect(S3Service).to receive(:store_file).with(expected_path, /PDF/)
        subject
        expect(decision_document.submitted_at).to eq(Time.zone.now + DecisionDocument::DECISION_OUTCODING_DELAY)
      end
    end

    context "when no file" do
      context "when :decision_document_upload feature is turned on" do
        it "raises NoFileError" do
          expect { subject }.to raise_error(DecisionDocument::NoFileError)
          expect(decision_document.submitted_at).to be_nil
        end
      end

      context "when :decision_document_upload feature is turned off" do
        before { FeatureToggle.disable!(:decision_document_upload) }

        it "marks document as having been processed immediately without uploading anything" do
          expect(S3Service).to_not receive(:store_file).with(expected_path, /PDF/)
          subject
          expect(decision_document.submitted_at).to eq(Time.zone.now)
          expect(decision_document.attempted_at).to eq(Time.zone.now)
          expect(decision_document.processed_at).to eq(Time.zone.now)
        end
      end
    end
  end

  context "#process!" do
    subject { decision_document.process! }

    context "when processing was successful" do
      context "when no granted issues" do
        it "uploads document and does not create effectuations" do
          expect(VBMSService).to receive(:upload_document_to_vbms).with(decision_document.appeal, decision_document)

          subject

          expect(decision_document.attempted_at).to eq(Time.zone.now)
          expect(decision_document.processed_at).to eq(Time.zone.now)
        end
      end

      context "when granted compensation issues" do
        let!(:granted_issue) do
          FactoryBot.create(
            :decision_issue,
            disposition: "allowed",
            decision_review: decision_document.appeal
          )
        end

        let!(:another_granted_issue) do
          FactoryBot.create(
            :decision_issue,
            disposition: "allowed",
            decision_review: decision_document.appeal
          )
        end

        it "uploads document and creates effectuations" do
          expect(VBMSService).to receive(:upload_document_to_vbms).with(decision_document.appeal, decision_document)

          subject

          expect(granted_issue.effectuation).to_not be_nil
          expect(granted_issue.effectuation).to have_attributes(
            appeal: decision_document.appeal,
            decision_document: decision_document,
            granted_decision_issue: granted_issue
          )

          expect(another_granted_issue.effectuation).to_not be_nil

          # some extra broader assertions to make sure the end products are the same for both issues
          expect(granted_issue.effectuation.end_product_establishment).to_not be_nil
          expect(granted_issue.effectuation.end_product_establishment).to eq(
            another_granted_issue.effectuation.end_product_establishment
          )

          expect(decision_document.attempted_at).to eq(Time.zone.now)
          expect(decision_document.processed_at).to eq(Time.zone.now)
        end
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
