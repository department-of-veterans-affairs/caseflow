class Reader::DocumentsController < ApplicationController
  before_action :verify_access

  def show
    # If we have sufficient metadata to show a single document,
    # then we'll render the show. Otherwise we want to render index
    # which will grab the metadata for all documents
    return render(:index) unless metadata?
  end

  private

  def appeal
    Appeal.find_or_create_by_vacols_id(appeal_id)
  end
  helper_method :appeal

  def documents
    document_ids = appeal.saved_documents.map(&:id)

    # Create a hash mapping each document_id that has been read to true
    read_documents_hash = current_user.document_views.where(document_id:  document_ids)
                                      .each_with_object({}) do |document_view, object|
      object[document_view.document_id] = true
    end

    @documents = appeal.saved_documents.map do |document|
      document.to_hash.tap do |object|
        object[:opened_by_current_user] = read_documents_hash[document.id] || false
        object[:tags] = document.tags
      end
    end
  end
  helper_method :documents

  def metadata?
    params[:received_at] && params[:type] && params[:filename]
  end

  # :nocov:
  def single_document
    Document.find(params[:id]).tap do |t|
      t.filename = params[:filename]
      t.type = params[:type]
      t.received_at = params[:received_at]
    end
  end
  helper_method :single_document
  # :nocov:

  def logo_name
    "Reader"
  end

  def appeal_id
    params[:appeal_id]
  end

  def logo_path
    reader_appeal_documents_path(appeal_id: appeal_id)
  end

  def verify_access
    verify_feature_enabled(:reader) &&
      verify_authorized_roles("Reader")
  end
end
