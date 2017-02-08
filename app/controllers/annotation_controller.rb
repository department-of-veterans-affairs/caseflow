class AnnotationController < ApplicationController
  before_action :verify_system_admin

  def create
    annotation = Annotation.create(
      annotation_params
    )
    render json: { success: false } if !annotation.valid?
    render json: { success: true, id: annotation.id }
  end

  def destroy
    render json: { success: Annotation.delete(params.require(:appeal_id)) }
  end

  def update
    render json: {success: 
      Annotation.find(params[:id]).update(
        annotation_params
      )}
  end

  def annotation_params
    params.require(:annotation).permit(:document_id, :page, :x, :y, :comment)
  end
end
