# frozen_string_literal: true

require "paper_trail"

class CorrespondenceDocumentController < ApplicationController
  def update_document
    document = CorrespondenceDocument.find(corr_document_params[:id])
    document.update!(corr_document_params)
    render json: { correspondence: serialized_correspondence(document.correspondence) }
  end

  private

  def corr_document_params
    params.permit(:id, :vbms_document_type_id)
  end

  def serialized_correspondence(correspondence)
    WorkQueue::CorrespondenceSerializer
      .new(correspondence)
      .serializable_hash[:data][:attributes]
  end
end
