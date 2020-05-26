# frozen_string_literal: true

RSpec.describe Reader::DocumentsController, :postgres, type: :controller do
  describe "GET /reader/appeal/:id/documents?json" do
    let!(:appeal) { create(:appeal) }
    let!(:documents) do
      [
        create(:document, type: "SSOC", received_at: 6.days.ago, file_number: appeal.veteran_file_number),
        create(:document, type: "SSOC", received_at: 7.days.ago, file_number: appeal.veteran_file_number)
      ]
    end

    before { User.authenticate!(roles: ["System Admin"]) }

    subject { get :index, params: { format: :json, appeal_id: appeal.uuid } }

    context "when efolder returns all documents stored" do
      before do
        allow_any_instance_of(DocumentFetcher).to receive(:find_or_create_documents!).and_return(documents)
        expect(Raven).to_not receive(:capture_exception)
      end

      it "does not send a sentry alert" do
        subject

        response_body = JSON.parse(response.body)
        expect(response_body["appealDocuments"].count).to eq documents.count
        expect(response_body["appealDocuments"].map { |doc| doc["id"] }).to match_array documents.map(&:id)
      end
    end

    context "when efolder returns half of the documents stored" do
      before do
        allow_any_instance_of(DocumentFetcher).to receive(:find_or_create_documents!).and_return([documents.first])
        expect(Raven).to receive(:capture_exception)
      end

      it "does sends a sentry alert" do
        subject

        response_body = JSON.parse(response.body)
        expect(response_body["appealDocuments"].count).to eq(documents.count / 2)
        expect(response_body["appealDocuments"].map { |doc| doc["id"] }).to match_array [documents.first].map(&:id)
      end
    end
  end
end
