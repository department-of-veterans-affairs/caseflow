# frozen_string_literal: true

require "paper_trail"

class CorrespondenceDocumentController < ApplicationController
  def update_document
    document = CorrespondenceDocument.find(params[:id])
    document.update!(update_params)
    render json: {}
  end

  def update_params
    params.permit(:vbms_document_type_id)
  end
end
