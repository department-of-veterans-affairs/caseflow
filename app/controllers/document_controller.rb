class DocumentController < ApplicationController
  before_action :verify_system_admin

  def set_label
    document = Document.find(params[:id])
    document.update!(label: label_params)
    render json: {}
  end

  def label_params
    params.require(:label)
  end
end
