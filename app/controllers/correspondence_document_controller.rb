# frozen_string_literal: true

require "paper_trail"

class CorrespondenceDocumentController < ApplicationController
  def update_document
    document = CorrespondenceDocument.find(corr_document_params[:id])
    document.update!(update_params)
    render json: { correspondence: document.correspondence }
  end

  def update_params
    params.permit(:vbms_document_type_id)
  end

  private

  def corr_document_params
    params.permit(:id)
  end
end
