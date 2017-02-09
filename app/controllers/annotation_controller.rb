class AnnotationController < ApplicationController
  before_action :verify_system_admin

  def create
    annotation = Annotation.create!(
      annotation_params
    )
    render json: { id: annotation.id }
  end

  def destroy
    binding.pry
    deleted = Annotation.delete(params.require(:id))
    render json: { error: "Failed to delete annotation" }, status: :internal_server_error if !deleted
    render json: { }
  end

  def update
    Annotation.find(params[:id]).update!(annotation_params)
    render json: { }
  end

  def annotation_params
    params.require(:annotation).permit(:document_id, :page, :x, :y, :comment)
  end
end
