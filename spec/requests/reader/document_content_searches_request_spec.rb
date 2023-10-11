# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reader::DocumentContentSearchesController", type: :request do
  let!(:user) { User.authenticate!(roles: ["Reader"]) }

  context "with a valid appeal" do
    context "when an appeal has documents" do
      let(:document1) { create(:document) }
      let(:document2) { create(:document) }
      let(:appeal) { create(:appeal, documents: [document1, document2]) }

      context "when matching text exists" do
        before do
          expect(ExternalApi::ClaimEvidenceService).to receive(:get_ocr_document).twice.and_return("foo bar baz")
        end

        it "successfully finds matching documents" do
          get "/reader/appeal/#{appeal.uuid}/document_content_searches?search_term=foo"

          expect(response).to have_http_status(:success)
          expect(response.body).to include(document1.vbms_document_id)
          expect(response.body).to include(document2.vbms_document_id)
        end
      end

      context "when matching text does not exist" do
        before do
          expect(ExternalApi::ClaimEvidenceService).to receive(:get_ocr_document).twice.and_return("The quick brown fox")
        end

        it "does not return documents that do not match" do
          get "/reader/appeal/#{appeal.uuid}/document_content_searches?search_term=owl"

          expect(response).to have_http_status(:success)
          expect(response.body).not_to include(document1.vbms_document_id)
          expect(response.body).not_to include(document2.vbms_document_id)
        end
      end
    end

    context "when an appeal does not have documents" do
      let(:appeal) { create(:appeal) }

      it "is successful" do
        get "/reader/appeal/#{appeal.uuid}/document_content_searches?search_term=foo"

        expect(response).to have_http_status(:success)
      end
    end
  end

  context "when the request is invalid" do
    let(:appeal) { create(:appeal) }

    it "does not find a nonexistent appeal" do
      get "/reader/appeal/0/document_content_searches?search_term=foo"

      expect(response).to have_http_status(:not_found)
    end

    it "does not search if the search param is missing" do
      get "/reader/appeal/#{appeal.uuid}/document_content_searches"

      expect(response).to have_http_status(:bad_request)
    end
  end
end
