# frozen_string_literal: true

describe CorrespondenceDocument, :postgres do
  let(:vet) { create(:veteran) }
  let(:cors) { create(:correspondence, veteran_id: vet.id) }
  let(:document) do
    create(
      :correspondence_document,
      document_file_number: vet.file_number,
      correspondence: cors,
      uuid: SecureRandom.uuid
    )
  end

  before do
    FeatureToggle.enable!(:correspondence_queue)
    S3Service.store_file(
      "#{CorrespondenceDocument::S3_BUCKET_NAME}/#{document.uuid}",
      "lib/pdfs/KnockKnockJokes.pdf", :filepath
    )
  end

  it "pdf_name returns name of pdf" do
    expect(document.pdf_name).to eq("#{document.uuid}.pdf")
  end

  it "s3_location returns path to doc in s3" do
    expect(document.s3_location).to eq("#{CorrespondenceDocument::S3_BUCKET_NAME}/#{document.uuid}")
  end

  it "pdf_location stores file fetched from S3" do
    document.pdf_location
    expect(document.output_location).to eq(File.join(Rails.root, "tmp", "pdfs", document.pdf_name).to_s)
  end
end
