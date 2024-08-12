# frozen_string_literal: true

require "paper_trail"

class DocumentController < ApplicationController
  before_action :verify_access

  # Currently update is being used for labels which will
  # be removed/changed soon. When we're using this for
  # a final feature, we'll add in a feature test to cover it
  # :nocov:
  def update
    document = Document.find(params[:id])
    document.update!(update_params)
    render json: {}
  end

  # :nocov:

  # TODO: Scope this down so that users can only see documents
  # associated with assigned appeals
  def pdf
    document = Document.find(params[:id])

    document_disposition = "inline"
    if params[:download]
      document_disposition = "attachment; filename='#{params[:type]}-#{params[:id]}.pdf'"
    end

    # The line below enables document caching for a month.
    expires_in 30.days, public: true
    send_file(
      document.serve,
      type: "application/pdf",
      disposition: document_disposition
    )
  end

  def mark_as_read
    begin
      DocumentView.find_or_create_by(
        document_id: params[:id],
        user_id: current_user.id
      ) do |t|
        t.update!(first_viewed_at: Time.zone.now)
      end
    rescue ActiveRecord::RecordNotUnique
      # We can ignore this exception because the race condition that causes it
      # means that another thread just created this record.
    end
    render json: {}
  end

  private

  def update_params
    params.permit(:category_procedural, :category_medical, :category_other, :description)
  end

  def verify_access
    verify_authorized_roles("Reader")
  end
end
