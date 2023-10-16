# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Reader::DocumentContentSearchesController", type: :request do
  let!(:user) { User.authenticate!(roles: ["Reader"]) }

  context "with a valid appeal" do
    context "when an appeal has documents" do
      let(:document1) { create(:document, series_id: "012345") }
      let(:document2) { create(:document, series_id: "678910") }
      let(:appeal) { create(:appeal, documents: [document1, document2]) }

      context "when matching text exists" do
        let(:document_contents) { "foo bar baz" }
        before do
          expect(ClaimEvidenceService).to receive(:get_ocr_document).twice.and_return(document_contents)
        end

        it "successfully finds matching documents" do
          get "/reader/appeal/#{appeal.uuid}/document_content_searches?search_term=foo"

          expect(response).to have_http_status(:success)
          expect(response.body).to include(document1.vbms_document_id)
          expect(response.body).to include(document2.vbms_document_id)
        end

        it "caches document contents from the claim evidence API" do
          get "/reader/appeal/#{appeal.uuid}/document_content_searches?search_term=foo"
          # check each doc has doc contents contained within the cache
          cache_key_1 = "claim_evidence_document_content_#{document1.series_id}"
          cache_key_2 = "claim_evidence_document_content_#{document2.series_id}"
          expect(Rails.cache.exist?(cache_key_1))
          expect(Rails.cache.fetch(cache_key_1)).to eq(document_contents)
          expect(Rails.cache.exist?(cache_key_2))
          expect(Rails.cache.fetch(cache_key_2)).to eq(document_contents)
        end
      end

      context "when matching text does not exist" do
        before do
          expect(ClaimEvidenceService).to receive(:get_ocr_document).twice.and_return("The quick brown fox")
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
