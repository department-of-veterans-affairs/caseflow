# frozen_string_literal: true

class AnnotationController < ApplicationController
  before_action :verify_access

  rescue_from ActiveRecord::RecordInvalid do |e|
    # This is prevented in the UI and should never happen.
    # :nocov:
    Rails.logger.error "AnnotationController failed validation: #{e.message}"

    render json: { "errors": ["title": e.class.to_s, "detail": e.message] }, status: :bad_request
    # :nocov:
  end

  def create
    annotation = Annotation.create!(annotation_params.merge(user_id: current_user.id))
    render json: { id: annotation.id }
  end

  def destroy
    Annotation.find(params.require(:id)).destroy
    render json: {}
  end

  def update
    Annotation.find(params[:id]).update!(annotation_params)
    render json: {}
  end

  def annotation_params
    params.require(:annotation).permit(:page, :x, :y, :comment, :relevant_date).merge(
      document_id: params[:document_id]
    )
  end

  def verify_access
    verify_authorized_roles("Reader")
  end
end
