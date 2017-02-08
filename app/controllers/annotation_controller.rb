class AnnotationController < ApplicationController
  before_action :verify_system_admin

  def create
    annotation = Annotation.create(
      annotation_params
    )
    render json: { errors: "Failed to delete annotation" }, status: :internal_server_error if !annotation.valid?
    render json: { id: annotation.id }
  end

  def destroy
    deleted = Annotation.delete(params.require(:id))
    render json: { error: "Failed to delete annotation" }, status: :internal_server_error if !deleted
    render json: { }
  end

  def update
    updated = Annotation.find(params[:id]).update(annotation_params)
    render json: { error: "Failed to delete annotation" }, status: :internal_server_error if !updated
    render json: { }
  end

  def annotation_params
    params.require(:annotation).permit(:document_id, :page, :x, :y, :comment)
  end
end
