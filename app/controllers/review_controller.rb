class ReviewController < ApplicationController
  before_action :verify_system_admin

  def index
    vacols_id = params[:vacols_id]
    @appeal = Appeal.find_or_create_by_vacols_id(vacols_id)
  end

  def logo_name
    "Decision"
  end

  # TODO: Scope this down so that users can only see documents
  # associated with assigned appeals
  def pdf
    document = Document.new(document_id: params[:document_id])

    send_file(
      document.serve,
      type: "application/pdf",
      disposition: "inline")
  end
end
