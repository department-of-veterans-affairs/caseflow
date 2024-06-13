# frozen_string_literal: true

# Translates JSON API responses into a format that's compatible with the legacy SOAP responses expected
# by most of Caseflow
class JsonApiResponseAdapter
  def adapt_fetch_document_series_for(json_response)
    documents = []

    return documents unless valid_json_response?(json_response)

    json_response.body["files"].each do |file_resp|
      documents.push(fetch_document_series_for_response(file_resp))
    end

    documents
  end

  private

  def valid_json_response?(json_response)
    return false if json_response&.body.blank?

    json_response.body.key?("files")
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
end
