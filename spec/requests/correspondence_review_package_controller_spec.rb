# frozen_string_literal: true

describe CorrespondenceReviewPackageController, type: :request do
  include ActionDispatch::TestProcess::FixtureFile

  let(:mail_team_supervisor_user) { create(:inbound_ops_team_supervisor) }

  describe "#pdf" do
    let(:mock_cmp_document_fetcher) { instance_double(CmpDocumentFetcher) }

    before do
      allow(CmpDocumentFetcher).to receive(:new).and_return(mock_cmp_document_fetcher)

      FeatureToggle.enable!(:correspondence_queue)

      InboundOpsTeam.singleton.add_user(mail_team_supervisor_user)
      User.authenticate!(user: mail_team_supervisor_user)
    end

    context "with vefs_integration feature toggle enabled" do
      let!(:cmp_document) { create(:cmp_document) }

      before do
        FeatureToggle.enable!(:vefs_integration)
      end

      after do
        FeatureToggle.disable!(:vefs_integration)
      end

      it "requests CMP document content" do
        expect(mock_cmp_document_fetcher).to receive(:get_cmp_document_content)
          .with(cmp_document.cmp_document_uuid)
          .and_return(fixture_file_upload("spec/fixtures/example.pdf", "application/pdf"))

        get(
          correspondence_review_package_pdf_path(pdf_id: cmp_document.id),
          params: { pdf: { pdf_id: cmp_document.id } },
          as: :json
        )

        expect(response).to be_successful
        expect(response.content_type).to eq("application/pdf")
      end
    end

    context "with vefs_integration feature toggle disabled" do
      let!(:document) { create(:document) }

      before do
        FeatureToggle.disable!(:vefs_integration)
      end

      it "uses dummy PDF data" do
        expect(mock_cmp_document_fetcher).not_to receive(:get_cmp_document_content)

        get(
          correspondence_review_package_pdf_path(pdf_id: document.id),
          params: { pdf: { pdf_id: document.id } },
          as: :json
        )

        expect(response).to be_successful
        expect(response.content_type).to eq("application/pdf")
      end
    end
  end
end
