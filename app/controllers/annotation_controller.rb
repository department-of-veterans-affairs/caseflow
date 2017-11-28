class AnnotationController < ApplicationController
  before_action :verify_access

  rescue_from ActiveRecord::RecordInvalid do |e|
    Rails.logger.error "#{e.message}\n#{e.backtrace.join("\n")}"
    Raven.capture_exception(e)

    render json: { "errors": ["status": 500, "title": e.class.to_s, "detail": e.message] }, status: 500
  end

  ANNOTATION_AUTHORIZED_ROLES = ["Reader"].freeze

  def create
    annotation = Annotation.create!(annotation_params.merge(user_id: current_user.id))
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
