# frozen_string_literal: true

describe CorrespondenceDocument, :postgres do
  # remove or update after implementing fetch from S3
  context "fetch_document" do
    let(:vet) { create(:veteran) }
    let(:cors) { create(:correspondence, veteran_id: vet.id) }
    let(:document) { create(:correspondence_document, document_file_number: vet.file_number, correspondence: cors) }

    before do
      FeatureToggle.enable!(:correspondence_queue)
      S3Service.store_file(
        "#{CorrespondenceDocument::S3_BUCKET_NAME}/#{document.uuid}",
        "lib/pdfs/KnockKnockJokes.pdf", :filepath
      )
    end
    after { FeatureToggle.disable!(:correspondence_queue) }

    it "returns document content" do
      expect(document.fetch_document).to eq(
        File.read(File.join(Rails.root, "lib", "pdfs", "KnockKnockJokes.pdf"))
      )
    end
  end
end
