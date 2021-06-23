# frozen_string_literal: true

class Reader::DocumentsController < Reader::ApplicationController
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
    @appeal ||= Appeal.find_appeal_by_uuid_or_find_or_create_legacy_appeal_by_vacols_id(appeal_id)
  end
  helper_method :appeal

  def annotations
    Annotation.where(document_id: document_ids).map(&:to_hash)
  end

  def document_ids
    @document_ids ||= appeal.document_fetcher.find_or_create_documents!.pluck(:id)
  end

  delegate :manifest_vbms_fetched_at, :manifest_vva_fetched_at, to: :appeal

  def documents
    # Create a hash mapping each document_id that has been read to true
    read_documents_hash = current_user.document_views.where(document_id: document_ids)
      .each_with_object({}) do |document_view, object|
      object[document_view.document_id] = true
    end

    tags_by_doc_id = load_tags_by_doc_id

    @documents = appeal.document_fetcher.find_or_create_documents!.map do |document|
      document.to_hash.tap do |object|
        object[:opened_by_current_user] = read_documents_hash[document.id] || false
        object[:tags] = tags_by_doc_id[document.id].to_a
      end
    end
  end

  def load_tags_by_doc_id
    tags_by_doc_id = Hash[document_ids.map { |key, _| [key, Set[]] }]
    Tag.includes(:documents_tags).where(documents_tags: { document_id: document_ids }).each do |tag|
      # tag.documents_tags returns extraneous documents outside document_ids, so
      # only capture tags associated with docs associated with document_ids
      (tag.documents_tags.pluck(:document_id) & document_ids).each do |doc_id|
        tags_by_doc_id[doc_id].add(tag)
      end
    end
    tags_by_doc_id
  end

  def appeal_id
    params[:appeal_id]
  end
end
