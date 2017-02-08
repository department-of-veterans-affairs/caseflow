class AnnotationController < ApplicationController
  before_action :verify_system_admin

  def index
    appeal = Appeal.find(params.require(:appeal_id))
    ids = appeal.documents.map do |doc|
      doc.id
    end
    annotations = [*Annotation.find_by(document_id: ids)]
    render json: { annotations: annotations.map(&:to_hash) }
  end

  def create
    annotation = Annotation.create(
      annotation_params
    )
    render json: { success: false } if !annotation.valid?
    render json: { success: true, id: annotation.id }
  end

  def destroy
    render json: { success: Annotation.delete(params[:id]) }
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
