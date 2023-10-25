describe CorrespondenceDocument, :postgres do

  context "fetch_content" do
    let(:vet) { create(:veteran) }
    let(:cors) { create(:correspondence, veteran_id: vet.id) }
    let(:document) { create(:correspondence_document, document_file_number: vet.file_number, correspondence: cors) }

    it "returns knock knock jokes content" do
      content = document.fetch_content
      expect(document.fetch).to include("Knock Knock Jokes")
    end
  end
end
