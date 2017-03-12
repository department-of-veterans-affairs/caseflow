class DocumentController < ApplicationController
  before_action :verify_system_admin

  def set_label
    document = Document.find(params[:id])
    document.update!(label: params[:label] || nil)
    render json: {}
  end

  def mark_as_read
    document_user = DocumentUser.find_or_create_by(
      document_id: params[:id],
      user_id: current_user.id)
    document_user.update!(viewed_at: Time.zone.now)
    render json: {}
  end
end
