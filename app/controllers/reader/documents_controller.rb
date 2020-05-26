# frozen_string_literal: true

class Reader::DocumentsController < Reader::ApplicationController
  class DocumentCountMismatch < StandardError; end

  def index
    respond_to do |format|
      format.html { return render "reader/appeal/index" }
      format.json do
        AppealView.find_or_create_by(appeal: appeal, user: current_user).update!(last_viewed_at: Time.zone.now)
        MetricsService.record "Get appeal #{appeal_id} document data" do
          render json: {
            appealDocuments: documents,
            annotations: annotations,
            manifestVbmsFetchedAt: manifest_vbms_fetched_at,
            manifestVvaFetchedAt: manifest_vva_fetched_at
          }
        end
      end
    end
  rescue StandardError => error
    raise error unless error.class.method_defined? :serialize_response

    render error.serialize_response
  end

  def show
    render "reader/appeal/index"
  end

  private

  def appeal
    @appeal ||= Appeal.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(appeal_id)
  end
  helper_method :appeal

  def annotations
    appeal.document_fetcher.find_or_create_documents!.flat_map(&:annotations).map(&:to_hash)
  end

  delegate :manifest_vbms_fetched_at, :manifest_vva_fetched_at, to: :appeal

  def documents
    document_ids = appeal.document_fetcher.find_or_create_documents!.map(&:id)

    capture_document_mismatch(document_ids)

    # Create a hash mapping each document_id that has been read to true
    read_documents_hash = current_user.document_views.where(document_id: document_ids)
      .each_with_object({}) do |document_view, object|
      object[document_view.document_id] = true
    end

    @documents = appeal.document_fetcher.find_or_create_documents!.map do |document|
      document.to_hash.tap do |object|
        object[:opened_by_current_user] = read_documents_hash[document.id] || false
        object[:tags] = document.tags
      end
    end
  end

  def capture_document_mismatch(ids)
    appeal_docs = Document.where(file_number: appeal.veteran_file_number).where.not(id: ids)

    if appeal_docs.present?
      error = DocumentCountMismatch.new("Document count mismatch")
      Raven.capture_exception(
        error,
        extra: {
          appeal_id: appeal.external_id,
          document_service: appeal.document_fetcher.document_service.name,
          missing_doc_ids: appeal_docs.pluck(:id),
          message: "`appeal.document_fetcher.find_or_create_documents!.map(&:id)` vs " \
                   "`Document.where(file_number: appeal.veteran_file_number)` "
        }
      )
    end
  end

  def appeal_id
    params[:appeal_id]
  end
end
