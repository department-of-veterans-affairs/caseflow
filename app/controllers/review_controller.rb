class ReviewController < ApplicationController
  before_action :verify_system_admin

  def index
    vbms_id = params[:vbms_id]
    @appeal = Appeal.find_or_create_by_vbms_id(vbms_id)
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
