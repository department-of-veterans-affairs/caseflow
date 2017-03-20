class ReviewController < ApplicationController
  before_action :verify_system_admin

  def index
    vacols_id = params[:vacols_id]
    @appeal = Appeal.find_or_create_by_vacols_id(vacols_id)

    document_ids = @appeal.saved_documents.map do |document|
      document.id
    end

    read_documents_hash = current_user.document_users.where(document_id:  document_ids).reduce({}) do |read_documents_hash, documents_user|
      read_documents_hash[documents_user.document_id] = true
      read_documents_hash
    end

    binding.pry

    @documents = @appeal.saved_documents.map do |document|
      document.to_hash.tap do |object|
        object[:opened_by_current_user] = read_documents_hash[document.id] || false
      end
    end
  end

  def logo_name
    "Decision"
  end

  def show
    @document = Document.find(document_param).tap do |t|
      t.filename = params[:filename]
      t.type = params[:type]
      t.received_at = params[:received_at]
    end
  end

  def document_param
    params.require(:id)
  end

  # TODO: Scope this down so that users can only see documents
  # associated with assigned appeals
  def pdf
    document = Document.find(params[:id])

    # The line below enables document caching for 48 hours.
    expires_in 30.days, public: true
    send_file(
      document.serve,
      type: "application/pdf",
      disposition: "inline")
  end
end
