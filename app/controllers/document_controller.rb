class DocumentController < ApplicationController
  before_action :verify_system_admin

  def set_label
    document = Document.find(params[:id])
    document.update!(label: params[:label] || nil)
    render json: {}
  end

  def mark_as_read
    DocumentView.find_or_create_by(
      document_id: params[:id],
      user_id: current_user.id).tap do |t|
      t.update!(first_viewed_at: Time.zone.now) if !t.first_viewed_at
    end
    render json: {}
  end
end
