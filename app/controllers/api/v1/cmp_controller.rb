# frozen_string_literal: true

class Api::V1::CmpController < Api::ApplicationController
  def upload
    endpoint_disabled("Payload is valid: #{validate_payload?}")
  rescue StandardError => error
    raise error
  end

  def document
    new_document = CmpDocument.new(cmp_document_params)

    if new_document.save
      render json: { message: "CMP document successfully created" }, status: :ok
    else
      render json: {
        message: "CMP document could not be created",
        errors: new_document.errors
      }, status: :unprocessable_entity
    end
  end

  def packet
    new_packet = CmpMailPacket.new(packet_params)
    # new_packet.update!(va_dor: new_packet.va_dor.strftime("%Y-%m-%d"))
    if new_packet.save
      binding.pry

      cmp_doc = CmpDocument.find_by(cmp_document_uuid: new_packet[:packet_uuid])
      cmp_doc.update!(cmp_mail_packet: new_packet)
      render json: { message: "CMP packet successfully created" }, status: :ok
    else
      render json: {
        message: "CMP document could not be created",
        errors: new_packet.errors
      }, status: :unprocessable_entity
    end
  end

  private

  def cmp_document_params
    {
      cmp_document_id: params.require(:documentId),
      cmp_document_uuid: params.require(:documentUUID),
      date_of_receipt: params.require(:dateOfReceipt).to_s,
      doctype_name: params.require(:nonVbmsDocTypeName),
      packet_uuid: params.require(:packetUUID),
      vbms_doctype_id: params.require(:vbmsDocTypeId)
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
end
