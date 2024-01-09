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
  end

  it "pdf_location gets file path of static document" do
    document.pdf_location
    expect(document.output_location).to eq(File.join(Rails.root, "tmp", "pdfs", document.pdf_name).to_s)
  end
end
