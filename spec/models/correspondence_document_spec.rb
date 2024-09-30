# frozen_string_literal: true

describe CorrespondenceDocument, :postgres do
  let(:vet) { create(:veteran) }
  let(:cors) { create(:correspondence, veteran_id: vet.id) }
  let(:user) { create(:user) }
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
    RequestStore[:current_user] = user
  end

  it "pdf_location gets file path of static document" do
    expect(document.pdf_location).to eq(File.join(Rails.root, "lib", "pdfs", "KnockKnockJokes.pdf").to_s)
  end

  describe "#update" do
    context "when correspondence documents have 10182" do
      it "updates correspondence nod to true" do
        document.update!(vbms_document_type_id: 1250)
        expect(document.correspondence.nod).to eq true
      end
    end

    context "when correspondence documents don't have 10182" do
      it "updates correspondence nod to false" do
        document.update!(vbms_document_type_id: 150)
        expect(document.correspondence.nod).to eq false
      end
    end
  end
end
