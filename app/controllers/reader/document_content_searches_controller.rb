# frozen_string_literal: true

class Reader::DocumentContentSearchesController < Reader::ApplicationController
  def search
    # Find the appeal or bail if not exists
    unless appeal = Appeal.find_appeal_by_uuid_or_find_or_create_legacy_appeal_by_vacols_id(params[:appeal_id])
      render json: { error: "appeal not found" }.to_json, status: :not_found
      return
    end

    # Get the search query from the URL or bail if not exists or is blank (search_term)
    unless search_term = params[:search_term]
      render json: { error: "search_term is required" }.to_json, status: :bad_request
      return
    end

    # Get docs for the appeal
    unless docs = appeal.document_fetcher.find_or_create_documents!
      render json: {}, status: :success
      return
    end

    # Loop docs and find matches in OCR data from CE API
    matched_docs = []

    docs.each do |doc|
      # use fetch to pull from cache or create in cache if not present
      query = Rails.cache.fetch("claim_evidence_document_content_#{doc.series_id}",
                                expires_in: 24.hours) do
        ClaimEvidenceService.get_ocr_document(doc.series_id)
      end

      if query.downcase.include?(search_term)
        matched_docs << doc
      end
    end

    render json: {
      appealDocuments: matched_docs
    }
  end
end
