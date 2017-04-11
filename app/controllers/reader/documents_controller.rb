class Reader::DocumentsController < ApplicationController
  before_action :verify_system_admin

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
      end
    end
  end
  helper_method :documents

  def single_document
    Document.find(params[:id]).tap do |t|
      t.filename = params[:filename]
      t.type = params[:type]
      t.received_at = params[:received_at]
    end
  end
  helper_method :single_document

  def logo_name
    "Reader"
  end

  def appeal_id
    params[:appeal_id]
  end

  def logo_path
    reader_appeal_documents_path(appeal_id: appeal_id)
  end
end
