# frozen_string_literal: true

class Api::V1::CmpController < Api::ApplicationController
  def upload
    endpoint_disabled("Payload is valid: #{validate_payload?}")
  rescue StandardError => error
    raise error
  end

  def document
    new_document = CmpDocument.new(document_params)

    if new_document.save
      render json: { message: "CMP document successfully created" }, status: :ok
    else
      render json: {
        message: "CMP document could not be created",
        errors: new_document.errors
      }, status: :unprocessable_entity
    end
  end

  private

  def document_params
    {
      cmp_document_id: params[:documentId],
      cmp_document_uuid: params[:documentUuid],
      date_of_receipt: params[:dateOfReceipt],
      doctype_name: params[:nonVbmsDocTypeName],
      packet_uuid: params[:packetUuid],
      vbms_doctype_id: params[:vbmsDocTypeId]
    }
  end

  def upload_params
    params.permit(:payload, file: [])
  end

  def validate_payload?
    payload = JSON.parse(upload_params[:payload])

    validate_provider_data?(payload["providerData"]) if payload.present?
  end

  def validate_provider_data?(provider_data)
    return false if provider_data.blank?

    Rails.logger.info("provider data is #{provider_data}")
    true
  end
end
