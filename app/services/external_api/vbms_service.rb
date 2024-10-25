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
      else
        Rails.logger.info(
          "VBMS HTTP Success #{status} (#{data.pretty_inspect})"
        )
      end
    end
  end
end
# :nocov:

class ExternalApi::VBMSService
  def self.fetch_document_file(document)
    DBService.release_db_connections

    if FeatureToggle.enabled?(:use_ce_api)
      verify_current_user_veteran_file_number_access(document.file_number)
      send_claim_evidence_request(
        class_name: VeteranFileFetcher,
        class_method: :get_document_content,
        method_args: { doc_series_id: document.series_id, claim_evidence_request: claim_evidence_request }
      )
    else
      @vbms_client ||= init_vbms_client

      vbms_id = document.vbms_document_id
      request = VBMS::Requests::GetDocumentContent.new(vbms_id)

      result = send_and_log_request(vbms_id, request)
      result&.content
    end
  end

  def self.fetch_documents_for(appeal, _user = nil)
    if FeatureToggle.enabled?(:use_ce_api)
      verify_current_user_veteran_access(appeal.veteran)

      response = send_claim_evidence_request(
        class_name: VeteranFileFetcher,
        class_method: :fetch_veteran_file_list,
        method_args: { veteran_file_number: appeal.veteran_file_number, claim_evidence_request: claim_evidence_request }
      )
      documents = JsonApiResponseAdapter.new.adapt_fetch_document_series_for(response)
      {
        manifest_vbms_fetched_at: nil,
        manifest_vva_fetched_at: nil,
        documents: DocumentsFromVbmsDocuments.new(documents: documents, file_number: appeal.veteran_file_number).call
      }
    else
      ExternalApi::VbmsDocumentsForAppeal.new(file_number: appeal.veteran_file_number).fetch
    end
  end

  def self.fetch_document_series_for(appeal)
    if FeatureToggle.enabled?(:use_ce_api)
      verify_current_user_veteran_access(appeal.veteran)
      response = send_claim_evidence_request(
        class_name: VeteranFileFetcher,
        class_method: :fetch_veteran_file_list,
        method_args: { veteran_file_number: appeal.veteran_file_number, claim_evidence_request: claim_evidence_request }
      )
      JsonApiResponseAdapter.new.adapt_fetch_document_series_for(response)
    else
      ExternalApi::VbmsDocumentSeriesForAppeal.new(file_number: appeal.veteran_file_number).fetch
    end
  end

  def self.update_document_in_vbms(appeal, uploadable_document)
    update_document(appeal, uploadable_document)
  end

  # rubocop:disable Metrics/MethodLength
  def self.upload_document_to_vbms(appeal, uploadable_document)
    if FeatureToggle.enabled?(:use_ce_api)
      filename = SecureRandom.uuid + File.basename(uploadable_document.pdf_location)
      file_upload_payload = ClaimEvidenceFileUploadPayload.new(
        content_name: filename,
        content_source: uploadable_document.source,
        date_va_received_document: Time.current.strftime("%Y-%m-%d"),
        document_type_id: uploadable_document.document_type_id,
        subject: uploadable_document.document_type,
        new_mail: true
      )
      response = send_claim_evidence_request(
        class_name: VeteranFileUploader,
        class_method: :upload_veteran_file,
        method_args: {
          file_path: uploadable_document.pdf_location,
          claim_evidence_request: claim_evidence_request,
          veteran_file_number: appeal.veteran_file_number,
          doc_info: file_upload_payload
        }
      )
      JsonApiResponseAdapter.new.adapt_upload_document(response)
    else
      @vbms_client ||= init_vbms_client
      response = initialize_upload(appeal, uploadable_document)
      upload_document(appeal.veteran_file_number, response.upload_token, uploadable_document.pdf_location)
    end
  end
  # rubocop:enable Metrics/MethodLength

  # rubocop:disable Metrics/MethodLength
  def self.upload_document_to_vbms_veteran(veteran_file_number, uploadable_document)
    if FeatureToggle.enabled?(:use_ce_api)
      filename = SecureRandom.uuid + File.basename(uploadable_document.pdf_location)
      file_upload_payload = ClaimEvidenceFileUploadPayload.new(
        content_name: filename,
        content_source: uploadable_document.source,
        date_va_received_document: Time.current.strftime("%Y-%m-%d"),
        document_type_id: uploadable_document.document_type_id,
        subject: uploadable_document.document_subject.presence || uploadable_document.document_type,
        new_mail: true
      )

      response = send_claim_evidence_request(
        class_name: VeteranFileUploader,
        class_method: :upload_veteran_file,
        method_args: {
          file_path: uploadable_document.pdf_location,
          claim_evidence_request: claim_evidence_request,
          veteran_file_number: veteran_file_number,
          doc_info: file_upload_payload
        }
      )
      JsonApiResponseAdapter.new.adapt_upload_document(response)
    else
      @vbms_client ||= init_vbms_client
      response = initialize_upload_veteran(veteran_file_number, uploadable_document)
      upload_document(veteran_file_number, response.upload_token, uploadable_document.pdf_location)
    end
  end
  # rubocop:enable Metrics/MethodLength

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

  def self.initialize_upload_veteran(veteran_file_number, uploadable_document)
    content_hash = Digest::SHA1.hexdigest(File.read(uploadable_document.pdf_location))
    filename = (uploadable_document.document_name.presence ||
      SecureRandom.uuid + File.basename(uploadable_document.pdf_location))
    request = VBMS::Requests::InitializeUpload.new(
      content_hash: content_hash,
      filename: filename,
      file_number: veteran_file_number,
      va_receive_date: Time.zone.now,
      doc_type: uploadable_document.document_type_id,
      source: uploadable_document.source,
      subject: uploadable_document.document_subject.presence || uploadable_document.document_type,
      new_mail: true
    )
    send_and_log_request(veteran_file_number, request)
  end

  def self.upload_document(vbms_id, upload_token, filepath)
    if !FeatureToggle.enabled?(:use_ce_api)
      request = VBMS::Requests::UploadDocument.new(
        upload_token: upload_token,
        filepath: filepath
      )
      send_and_log_request(vbms_id, request)
    end
  end

  def self.initialize_update(appeal, uploadable_document)
    content_hash = Digest::SHA1.hexdigest(File.read(uploadable_document.pdf_location))
    request = VBMS::Requests::InitializeUpdate.new(
      content_hash: content_hash,
      document_version_reference_id: uploadable_document.document_version_reference_id,
      va_receive_date: Time.zone.now,
      subject: uploadable_document.document_subject.presence || uploadable_document.document_type
    )
    send_and_log_request(appeal.veteran_file_number, request)
  end

  # rubocop:disable Metrics/MethodLength
  def self.update_document(appeal, uploadable_document)
    if FeatureToggle.enabled?(:use_ce_api)
      file_update_payload = ClaimEvidenceFileUpdatePayload.new(
        date_va_received_document: Time.current.strftime("%Y-%m-%d"),
        document_type_id: uploadable_document.document_type_id,
        file_content_path: uploadable_document.pdf_location,
        file_content_source: uploadable_document.source,
        subject: uploadable_document.document_subject.presence || uploadable_document.document_type
      )

      file_uuid = uploadable_document.document_series_reference_id.delete("{}")

      response = send_claim_evidence_request(
        class_name: VeteranFileUpdater,
        class_method: :update_veteran_file,
        method_args: {
          veteran_file_number: appeal.veteran_file_number,
          claim_evidence_request: claim_evidence_request,
          file_uuid: file_uuid,
          file_update_payload: file_update_payload
        }
      )
      JsonApiResponseAdapter.new.adapt_update_document(response)
    else
      @vbms_client ||= init_vbms_client
      response = initialize_update(appeal, uploadable_document)
      request = VBMS::Requests::UpdateDocument.new(
        upload_token: response.updated_document_token,
        filepath: uploadable_document.pdf_location
      )
      send_and_log_request(appeal.veteran_file_number, request)
    end
  end
  # rubocop:enable Metrics/MethodLength

  def self.clean_document(location)
    File.delete(location)
  end

  def self.establish_claim!(veteran_hash:, claim_hash:, user:)
    @vbms_client ||= init_vbms_client

    request = VBMS::Requests::EstablishClaim.new(
      veteran_hash,
      claim_hash,
      v5: true,
      send_userid: true
    )

    send_and_log_request(veteran_hash[:file_number], request, vbms_client_with_user(user))
  end

  def self.fetch_contentions(claim_id:)
    @vbms_client ||= init_vbms_client

    request = VBMS::Requests::ListContentions.new(
      claim_id,
      v5: true
    )

    send_and_log_request(claim_id, request)
  end

  def self.create_contentions!(veteran_file_number:, claim_id:, contentions:, claim_date:, user:)
    # Contentions should be an array of objects representing the contention descriptions and special issues
    # [{description: "contention description", special_issues: [{ code: "SSR", narrative: "Same Station Review" }]}]
    @vbms_client ||= init_vbms_client

    request = VBMS::Requests::CreateContentions.new(
      veteran_file_number: veteran_file_number,
      claim_id: claim_id,
      contentions: contentions,
      claim_date: claim_date,
      v5: true,
      send_userid: true
    )

    send_and_log_request(claim_id, request, vbms_client_with_user(user))
  end

  def self.remove_contention!(contention)
    @vbms_client ||= init_vbms_client

    request = VBMS::Requests::RemoveContention.new(
      contention: contention,
      v5: true,
      send_userid: true
    )

    send_and_log_request(contention.claim_id, request, vbms_client_with_user(User.system_user))
  end

  def self.update_contention!(contention)
    @vbms_client ||= init_vbms_client

    request = VBMS::Requests::UpdateContention.new(
      contention: contention,
      v5: true,
      send_userid: true
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
  end

  def self.call_and_log_service(service:, vbms_id:)
    name = service.class.name.split("::").last
    MetricsService.record("call #{service.class} for #{vbms_id}",
                          service: :vbms,
                          name: name) do
      service.call(file_number: vbms_id)
    end
  end

  def self.verify_current_user_veteran_access(veteran)
    current_user = RequestStore[:current_user]

    # Non-UI invocations (i.e., jobs) may not set the current user,
    # in which case we do not need to check sensitivity
    return if current_user.blank?

    fail BGS::SensitivityLevelCheckFailure, "User does not have permission to access this information" unless
      SensitivityChecker.new(current_user).sensitivity_levels_compatible?(
        user: current_user,
        veteran: veteran
      )
  end

  def self.verify_current_user_veteran_file_number_access(file_number)
    return if file_number.blank?

    veteran = Veteran.find_by_file_number_or_ssn(file_number)
    verify_current_user_veteran_access(veteran)
  end

  def self.claim_evidence_request
    ClaimEvidenceRequest.new(
      user_css_id: send_user_info? ? RequestStore[:current_user].css_id : ENV["CLAIM_EVIDENCE_VBMS_USER"],
      station_id: send_user_info? ? RequestStore[:current_user].station_id : ENV["CLAIM_EVIDENCE_STATION_ID"]
    )
  end

  def self.send_user_info?
    RequestStore[:current_user].present? && FeatureToggle.enabled?(:send_current_user_cred_to_ce_api)
  end

  class << self
    private

    def send_claim_evidence_request(class_name:, class_method:, method_args:)
      class_name.public_send(class_method, **method_args)
    rescue StandardError => error
      current_user = RequestStore[:current_user]
      user_sensitivity_level = if current_user.present?
                                 SensitivityChecker.new(current_user).sensitivity_level_for_user(current_user)
                               else
                                 "User is not set in the RequestStore"
                               end
      error_details = {
        user_css_id: current_user&.css_id || "User is not set in the RequestStore",
        user_sensitivity_level: user_sensitivity_level,
        error_uuid: SecureRandom.uuid
      }
      ErrorHandlers::ClaimEvidenceApiErrorHandler.new.handle_error(error: error, error_details: error_details)

      nil
    end
  end
end
