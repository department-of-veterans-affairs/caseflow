# frozen_string_literal: true

# Translates JSON API responses into a format that's compatible with the legacy SOAP responses expected
# by most of Caseflow
class JsonApiResponseAdapter
  def adapt_fetch_document_series_for(json_response)
    documents = []

    json_response = normalize_json_response(json_response)
    return documents unless json_response.key?("files")

    json_response["files"].each do |file_resp|
      documents.push(fetch_document_series_for_response(file_resp))
    end

    documents
  end

  def adapt_upload_document(json_response)
    document_upload_response(
      normalize_json_response(json_response)
    )
  end

  def adapt_update_document(json_response)
    document_update_response(
      normalize_json_response(json_response)
    )
  end

  private

  def normalize_json_response(json_response)
    if json_response.blank?
      {}
    elsif json_response.instance_of?(Hash)
      json_response.with_indifferent_access
    elsif json_response.instance_of?(String)
      JSON.parse(json_response)
    end
  end

  def fetch_document_series_for_response(file_json)
    system_data = file_json["currentVersion"]["systemData"]
    provider_data = file_json["currentVersion"]["providerData"]

    OpenStruct.new(
      document_id: "{#{file_json['currentVersionUuid'].upcase}}",
      series_id: "{#{file_json['uuid'].upcase}}",
      version: "1",
      type_description: provider_data["subject"],
      type_id: provider_data["documentTypeId"],
      doc_type: provider_data["documentTypeId"],
      subject: provider_data["subject"],
      # gsub here so that JS will correctly handle this date
      # (with dashes the date is 1 day off due to UTC issues)
      received_at: provider_data["dateVaReceivedDocument"]&.gsub("-", "/"),
      source: provider_data["contentSource"],
      mime_type: system_data["mimeType"],
      alt_doc_types: nil,
      restricted: nil,
      upload_date: system_data["uploadedDateTime"]
    )
  end

  def document_upload_response(file_json)
    OpenStruct.new(
      upload_document_response: {
        "@new_document_version_ref_id": file_json["currentVersionUuid"],
        "@document_series_ref_id": file_json["uuid"]
      }
    )
  end

  def document_update_response(file_json)
    OpenStruct.new(
      update_document_response: {
        "@new_document_version_ref_id": file_json["currentVersionUuid"],
        "@document_series_ref_id": file_json["uuid"]
      }
    )
  end
end
