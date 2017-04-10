class AnnotationController < ApplicationController
  before_action :verify_system_admin

  def create
    annotation = Annotation.create!(annotation_params) do |t|
      t.document_id = params[:document_id]
    end
    render json: { id: annotation.id }
  end

  def destroy
    Annotation.find(params.require(:id)).delete
    render json: {}
  end

  def update
    Annotation.find(params[:id]).update!(annotation_params) do |t|
      t.document_id = params[:document_id]
    end
    render json: {}
  end

  def annotation_params
    params.require(:annotation).permit(:page, :x, :y, :comment)
  end
end
