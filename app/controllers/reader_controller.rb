class ReaderController < ApplicationController
  before_action :verify_system_admin

  # :nocov:
  def index
    vacols_id = params[:vacols_id]
    @appeal = Appeal.find_or_create_by_vacols_id(vacols_id)

    document_ids = @appeal.saved_documents.map(&:id)

    # Create a hash mapping each document_id that has been read to true
    read_documents_hash = current_user.document_views.where(document_id:  document_ids)
                                      .each_with_object({}) do |document_view, object|
      object[document_view.document_id] = true
    end

    @documents = @appeal.saved_documents.map do |document|
      document.to_hash.tap do |object|
        object[:opened_by_current_user] = read_documents_hash[document.id] || false
      end
    end
  end

  def logo_name
    "Reader"
  end

  def logo_path
    reader_index_path(vacols_id: params[:vacols_id])
  end


  def show
    vacols_id = params[:vacols_id]
    @appeal = Appeal.find_or_create_by_vacols_id(vacols_id)

    @document = Document.find(document_param).tap do |t|
      t.filename = params[:filename]
      t.type = params[:type]
      t.received_at = params[:received_at]
    end
  end

  def document_param
    params.require(:document_id)
  end

  # TODO: Scope this down so that users can only see documents
  # associated with assigned appeals
  def pdf
    document = Document.find(params[:document_id])

    # The line below enables document caching for 48 hours.
    expires_in 30.days, public: true
    send_file(
      document.serve,
      type: "application/pdf",
      disposition: "inline")
  end
  # :nocov:
end
