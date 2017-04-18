class AnnotationController < ApplicationController
  before_action :verify_access

  ANNOTATION_AUTHORIZED_ROLES = ["Reader"]

  def create
    annotation = Annotation.create!(annotation_params)
    render json: { id: annotation.id }
  end

  def destroy
    Annotation.find(params.require(:id)).delete
    render json: {}
  end

  def update
    Annotation.find(params[:id]).update!(annotation_params)
    render json: {}
  end

  def annotation_params
    params.require(:annotation).permit(:page, :x, :y, :comment).merge(
      document_id: params[:document_id]
    )
  end

  def verify_access
    verify_authorized_roles(ANNOTATION_AUTHORIZED_ROLES.join(" "))
  end
end
