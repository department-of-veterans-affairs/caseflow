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
    
    document = Document.find_by(vbms_document_id: params[:vbms_document_id])
    #expires_in 12.hours, :public => true
    send_file(
      document.serve,
      type: "application/pdf",
      disposition: "inline")
  end

  def get_annotations
    annotations = Annotation.where(document_id: params[:document_id])
    render json: { annotations: annotations.map(&:to_hash) }
  end

  def add_annotation
    annotation = params[:annotation]
    annotation = Annotation.create(
      document_id: annotation[:document_id],
      page: annotation[:page],
      x_location: annotation[:x],
      y_location: annotation[:y],
      comment: annotation[:comment]
    )
    render json: { id: annotation.id }
  end

  def delete_annotation
    binding.pry
    annotation_id = params[:annotation_id]
    Annotation.where(id: annotation_id).delete
    render json: {}
  end
end
