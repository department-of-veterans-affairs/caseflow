class ReviewController < ApplicationController
  def index
    vbms_id = params[:vbms_id]
    @appeal = Appeal.find_or_create_by_vbms_id(vbms_id)
    render layout: "full_screen"
  end

  def logo_name
    "Decision"
  end

  def pdf
    document = Document.new(document_id: params[:document_id])

    send_file(
      document.serve,
      type: "application/pdf",
      disposition: "inline")
  end
end
