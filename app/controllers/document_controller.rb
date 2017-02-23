class DocumentController < ApplicationController
  before_action :verify_system_admin

  def set_label
    document = Document.find(params[:id])
    document.update!(label: params[:label])
    render json: {}
  end
end
