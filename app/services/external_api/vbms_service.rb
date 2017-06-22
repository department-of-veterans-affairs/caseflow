# :nocov:
class VBMSCaseflowLogger
  def log(event, data)
    case event
    when :request
      status = data[:response_code]
      name = data[:request].class.name.split("::").last

      if status != 200
        Rails.logger.error(
          "VBMS HTTP Error #{status} " \
          "(#{name}) #{data[:response_body]}"
        )
      end
    end
  end
end
# :nocov:

class ExternalApi::VBMSService
  def self.fetch_document_file(document)
    @vbms_client ||= init_vbms_client

    vbms_id = document.vbms_document_id
    request = if FeatureToggle.enabled?(:vbms_efolder_service_v1)
                VBMS::Requests::GetDocumentContent.new(vbms_id)
              else
                VBMS::Requests::FetchDocumentById.new(vbms_id)
              end
    result = send_and_log_request(vbms_id, request)
    result && result.content
  end

  def self.fetch_documents_for(appeal)
    @vbms_client ||= init_vbms_client

    sanitized_id = appeal.sanitized_vbms_id
    request = if FeatureToggle.enabled?(:vbms_efolder_service_v1)
                VBMS::Requests::FindDocumentSeriesReference.new(sanitized_id)
              else
                VBMS::Requests::ListDocuments.new(sanitized_id)
              end
    documents = send_and_log_request(sanitized_id, request)

    Rails.logger.info("Document list length: #{documents.length}")

    documents.map do |vbms_document|
      Document.from_vbms_document(vbms_document)
    end
  end

  def self.upload_document_to_vbms(appeal, form8)
    @vbms_client ||= init_vbms_client
    document = if FeatureToggle.enabled?(:vbms_efolder_service_v1)
                 response = initialize_upload(appeal, form8)
                 upload_document(appeal.vbms_id, response.upload_token, form8.pdf_location)
               else
                 upload_document_deprecated(appeal, form8)
               end
    document
  end

  def self.initialize_upload(appeal, uploadable_document)
    content_hash = Digest::SHA1.hexdigest(File.read(uploadable_document.pdf_location))
    filename = SecureRandom.uuid + File.basename(uploadable_document.pdf_location)
    request = VBMS::Requests::InitializeUpload.new(
      content_hash: content_hash,
      filename: filename,
      file_number: appeal.sanitized_vbms_id,
      va_receive_date: uploadable_document.upload_date,
      doc_type: uploadable_document.document_type_id,
      source: "VACOLS",
      subject: uploadable_document.document_type,
      new_mail: true
    )
    send_and_log_request(appeal.vbms_id, request)
  end

  def self.upload_document_deprecated(appeal, uploadable_document)
    request = VBMS::Requests::UploadDocumentWithAssociations.new(
      appeal.sanitized_vbms_id,
      uploadable_document.upload_date,
      appeal.veteran_first_name,
      appeal.veteran_middle_initial,
      appeal.veteran_last_name,
      uploadable_document.document_type,
      uploadable_document.pdf_location,
      uploadable_document.document_type_id,
      "VACOLS",
      true
    )
    send_and_log_request(appeal.vbms_id, request)
  end

  def self.upload_document(vbms_id, upload_token, filepath)
    request = VBMS::Requests::UploadDocument.new(
      upload_token: upload_token,
      filepath: filepath
    )
    send_and_log_request(vbms_id, request)
  end

  def self.clean_document(location)
    File.delete(location)
  end

  def self.establish_claim!(veteran_hash:, claim_hash:)
    @vbms_client ||= init_vbms_client

    request = VBMS::Requests::EstablishClaim.new(veteran_hash, claim_hash)

    send_and_log_request(veteran_hash[:file_number], request)
  end

  def self.init_vbms_client
    VBMS::Client.from_env_vars(
      logger: VBMSCaseflowLogger.new,
      env_name: ENV["CONNECT_VBMS_ENV"]
    )
  end

  def self.send_and_log_request(vbms_id, request)
    name = request.class.name.split("::").last
    MetricsService.record("sent VBMS request #{request.class} for #{vbms_id}",
                          service: :vbms,
                          name: name) do
      @vbms_client.send_request(request)
    end

  rescue VBMS::ClientError => e
    Raven.capture_exception(e)
    Rails.logger.error "#{e.message}\n#{e.backtrace.join("\n")}"

    raise e
  end
end
