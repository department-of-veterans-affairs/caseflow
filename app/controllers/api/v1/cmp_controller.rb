# frozen_string_literal: true

class Api::V1::CmpController < Api::ApplicationController
  def upload
    endpoint_disabled("Payload is valid: #{validate_payload?}")
  rescue StandardError => error
    raise error
  end

  def document
    return unprocessable_response("Invalid params") unless cmp_response_validator
      .validate_cmp_document_request(cmp_document_params)

    new_document = CmpDocument.new(cmp_document_params)

    if new_document.save
      render json: { message: "CMP document successfully created" }, status: :ok
    else
      unprocessable_response("Cmp document could not be created.", new_document)
    end
  end

  def packet
    return unprocessable_response("Invalid params") unless cmp_response_validator
      .validate_cmp_mail_packet_request(packet_params)

    new_packet = CmpMailPacket.new(packet_params)
    cmp_doc = CmpDocument.find_by(cmp_document_uuid: packet_params[:packet_uuid])

    return unprocessable_response("Cmp doc not found.") if cmp_doc.blank?

    if new_packet.save
      cmp_doc.update!(cmp_mail_packet: new_packet)
      render json: { message: "CMP packet successfully created" }, status: :ok
    else
      unprocessable_response("Packet could not be created.", new_packet)
    end
  end

  private

  def cmp_document_params
    {
      cmp_document_id: params[:documentId],
      cmp_document_uuid: params[:documentUuid],
      date_of_receipt: params[:dateOfReceipt],
      doctype_name: params[:nonVbmsDocTypeName],
      packet_uuid: params[:packetUuid],
      vbms_doctype_id: params[:vbmsDocTypeId]
    }
  end

  def packet_params
    {
      packet_uuid: params[:packetUUID],
      cmp_packet_number: params[:cmpPacketNumber],
      packet_source: params[:packetSource],
      va_dor: params[:vaDor],
      veteran_id: params[:veteranId],
      veteran_first_name: params[:veteranFirstName],
      veteran_middle_initial: params[:veteranMiddleName],
      veteran_last_name: params[:veteranLastName]
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

  def cmp_response_validator
    @cmp_response_validator ||= CmpResponseValidator.new
  end

  def unprocessable_response(message, unprocessable_object = nil)
    render json: {
      message: message,
      errors: unprocessable_object&.errors
    }, status: :error
  end
end
