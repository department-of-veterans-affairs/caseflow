describe CorrespondenceDocument, :postgres do

  # remove or update after implementing fetch from S3
  context "fetch_document" do
    let(:vet) { create(:veteran) }
    let(:cors) { create(:correspondence, veteran_id: vet.id) }
    let(:document) { create(:correspondence_document, document_file_number: vet.file_number, correspondence: cors) }

    before { FeatureToggle.enable!(:correspondence_queue) }
    after { FeatureToggle.disable!(:correspondence_queue) }

    it "returns knock knock jokes filepath" do
      expect(document.fetch_document).to include("/lib/pdfs/KnockKnockJokes.pdf")
    end
  end
end
