# frozen_string_literal: true

# :nocov:
class VBMSCaseflowLogger
  def log(event, data)
    case event
    when :request
      status = data[:response_code]

      if status != 200
        Rails.logger.error(
          "VBMS HTTP Error #{status} (#{data.pretty_inspect})"
        )
      end
    end
  end
end
# :nocov:

class ExternalApi::VBMSService
  def self.fetch_document_file(document)
    DBService.release_db_connections

    @vbms_client ||= init_vbms_client

    vbms_id = document.vbms_document_id
    request = VBMS::Requests::GetDocumentContent.new(vbms_id)

    result = send_and_log_request(vbms_id, request)
    result&.content
  end

  def self.fetch_documents_for(appeal, _user = nil)
    DBService.release_db_connections

    @vbms_client ||= init_vbms_client

    veteran_file_number = appeal.veteran_file_number
    request = VBMS::Requests::FindDocumentVersionReference.new(veteran_file_number)

    begin
      documents = send_and_log_request(veteran_file_number, request)
    rescue VBMSError::FilenumberDoesNotExist
      alternative_file_number = ExternalApi::BGSService.new.fetch_veteran_info(veteran_file_number)[:claim_number]

      raise if alternative_file_number == veteran_file_number

      request = VBMS::Requests::FindDocumentVersionReference.new(alternative_file_number)
      documents = send_and_log_request(alternative_file_number, request)
    end

    Rails.logger.info("Document list length: #{documents.length}")

    {
      manifest_vbms_fetched_at: nil,
      manifest_vva_fetched_at: nil,
      documents: documents.map { |vbms_document| Document.from_vbms_document(vbms_document, veteran_file_number) }
    }
  end

  def self.fetch_document_series_for(appeal)
    DBService.release_db_connections

    @vbms_client ||= init_vbms_client

    veteran_file_number = appeal.veteran_file_number
    request = VBMS::Requests::FindDocumentSeriesReference.new(veteran_file_number)

    send_and_log_request(veteran_file_number, request)
  end

  def self.upload_document_to_vbms(appeal, uploadable_document)
    @vbms_client ||= init_vbms_client
    response = initialize_upload(appeal, uploadable_document)
    upload_document(appeal.veteran_file_number, response.upload_token, uploadable_document.pdf_location)
  end

  def self.initialize_upload(appeal, uploadable_document)
    content_hash = Digest::SHA1.hexdigest(File.read(uploadable_document.pdf_location))
    filename = SecureRandom.uuid + File.basename(uploadable_document.pdf_location)
    request = VBMS::Requests::InitializeUpload.new(
      content_hash: content_hash,
      filename: filename,
      file_number: appeal.veteran_file_number,
      va_receive_date: Time.zone.now,
      doc_type: uploadable_document.document_type_id,
      source: uploadable_document.source,
      subject: uploadable_document.document_type,
      new_mail: true
    )
    send_and_log_request(appeal.veteran_file_number, request)
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

  def self.establish_claim!(veteran_hash:, claim_hash:, user:)
    @vbms_client ||= init_vbms_client

    request = VBMS::Requests::EstablishClaim.new(
      veteran_hash,
      claim_hash,
      v5: FeatureToggle.enabled?(:claims_service_v5),
      send_userid: FeatureToggle.enabled?(:vbms_include_user)
    )

    send_and_log_request(veteran_hash[:file_number], request, vbms_client_with_user(user))
  end

  def self.fetch_contentions(claim_id:)
    @vbms_client ||= init_vbms_client

    request = VBMS::Requests::ListContentions.new(
      claim_id,
      v5: FeatureToggle.enabled?(:claims_service_v5)
    )

    send_and_log_request(claim_id, request)
  end

  def self.create_contentions!(veteran_file_number:, claim_id:, contentions:, user:)
    # Contentions should be an array of objects representing the contention descriptions and special issues
    # [{description: "contention description", special_issues: [{ code: "SSR", narrative: "Same Station Review" }]}]
    @vbms_client ||= init_vbms_client

    request = VBMS::Requests::CreateContentions.new(
      veteran_file_number: veteran_file_number,
      claim_id: claim_id,
      contentions: contentions,
      v5: FeatureToggle.enabled?(:claims_service_v5),
      send_userid: FeatureToggle.enabled?(:vbms_include_user)
    )

    send_and_log_request(claim_id, request, vbms_client_with_user(user))
  end

  def self.remove_contention!(contention)
    @vbms_client ||= init_vbms_client

    request = VBMS::Requests::RemoveContention.new(
      contention: contention,
      v5: FeatureToggle.enabled?(:claims_service_v5),
      send_userid: FeatureToggle.enabled?(:vbms_include_user)
    )

    send_and_log_request(contention.claim_id, request, vbms_client_with_user(User.system_user))
  end

  def self.update_contention!(contention)
    @vbms_client ||= init_vbms_client

    request = VBMS::Requests::UpdateContention.new(
      contention: contention,
      v5: FeatureToggle.enabled?(:claims_service_v5),
      send_userid: FeatureToggle.enabled?(:vbms_include_user)
    )

    send_and_log_request(contention.claim_id, request, vbms_client_with_user(User.system_user))
  end

  def self.associate_rating_request_issues!(claim_id:, rating_issue_contention_map:)
    # rating_issue_contention_map format: { issue_id: contention_id, issue_id2: contention_id2 }
    @vbms_client ||= init_vbms_client

    request = VBMS::Requests::AssociateRatedIssues.new(
      claim_id: claim_id,
      rated_issue_contention_map: rating_issue_contention_map
    )

    send_and_log_request(claim_id, request)
  end

  def self.get_dispositions!(claim_id:)
    @vbms_client ||= init_vbms_client

    request = VBMS::Requests::GetDispositions.new(claim_id: claim_id)

    send_and_log_request(claim_id, request)
  end

  def self.list_document_types
    @vbms_client ||= init_vbms_client

    request = VBMS::Requests::ListTypeCategory.new

    send_and_log_request(nil, request)
  end

  def self.vbms_client_with_user(user)
    return @vbms_client if user.nil?

    VBMS::Client.from_env_vars(
      logger: VBMSCaseflowLogger.new,
      env_name: ENV["CONNECT_VBMS_ENV"],
      css_id: user.css_id,
      station_id: user.station_id,
      use_forward_proxy: FeatureToggle.enabled?(:vbms_forward_proxy)
    )
  end

  def self.init_vbms_client
    VBMS::Client.from_env_vars(
      logger: VBMSCaseflowLogger.new,
      env_name: ENV["CONNECT_VBMS_ENV"],
      use_forward_proxy: FeatureToggle.enabled?(:vbms_forward_proxy)
    )
  end

  def self.send_and_log_request(vbms_id, request, override_vbms_client = nil)
    name = request.class.name.split("::").last
    MetricsService.record("sent VBMS request #{request.class} for #{vbms_id}",
                          service: :vbms,
                          name: name) do
      (override_vbms_client || @vbms_client).send_request(request)
    end
  rescue VBMS::ClientError => error
    Rails.logger.error "#{error.message}\n#{error.backtrace.join("\n")}"

    raise VBMSError.from_vbms_http_error(error)
  end
end
