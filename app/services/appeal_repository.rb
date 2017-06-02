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

class AppealRepository
  # :nocov:
  # Returns a boolean saying whether the load succeeded
  def self.load_vacols_data(appeal)
    case_record = MetricsService.record("VACOLS: load_vacols_data #{appeal.vacols_id}",
                                        service: :vacols,
                                        name: "load_vacols_data") do
      VACOLS::Case.includes(:folder, :correspondent).find(appeal.vacols_id)
    end

    set_vacols_values(appeal: appeal, case_record: case_record)

    true

  rescue ActiveRecord::RecordNotFound
    return false
  end

  def self.appeals_by_vbms_id(vbms_id)
    cases = MetricsService.record("VACOLS: appeals_by_vbms_id",
                                  service: :vacols,
                                  name: "appeals_by_vbms_id") do
      VACOLS::Case.where(bfcorlid: vbms_id).includes(:folder, :correspondent)
    end

    cases.map { |case_record| build_appeal(case_record) }
  end

  def self.load_vacols_data_by_vbms_id(appeal:, decision_type:)
    case_scope = case decision_type
                 when "Full Grant"
                   VACOLS::Case.amc_full_grants(outcoded_after: 5.days.ago)
                 when "Partial Grant or Remand"
                   VACOLS::Case.remands_ready_for_claims_establishment
                 else
                   VACOLS::Case.includes(:folder, :correspondent)
                 end

    case_records = MetricsService.record("VACOLS: load_vacols_data_by_vbms_id #{appeal.vbms_id}",
                                         service: :vacols,
                                         name: "load_vacols_data_by_vbms_id") do
      case_scope.where(bfcorlid: appeal.vbms_id)
    end

    return false if case_records.empty?
    fail Caseflow::Error::MultipleAppealsByVBMSID if case_records.length > 1

    appeal.vacols_id = case_records.first.bfkey
    set_vacols_values(appeal: appeal, case_record: case_records.first)

    appeal
  end
  # :nocov:

  # TODO: consider persisting these records
  def self.build_appeal(case_record)
    appeal = Appeal.find_or_initialize_by(vacols_id: case_record.bfkey)
    set_vacols_values(appeal: appeal, case_record: case_record)
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def self.set_vacols_values(appeal:, case_record:)
    correspondent_record = case_record.correspondent
    folder_record = case_record.folder

    appeal.assign_from_vacols(
      vbms_id: case_record.bfcorlid,
      type: VACOLS::Case::TYPES[case_record.bfac],
      file_type: folder_type_from(folder_record),
      representative: VACOLS::Case::REPRESENTATIVES[case_record.bfso][:full_name],
      veteran_first_name: correspondent_record.snamef,
      veteran_middle_initial: correspondent_record.snamemi,
      veteran_last_name: correspondent_record.snamel,
      appellant_first_name: correspondent_record.sspare1,
      appellant_middle_initial: correspondent_record.sspare2,
      appellant_last_name: correspondent_record.sspare3,
      appellant_relationship: correspondent_record.sspare1 ? correspondent_record.susrtyp : "",
      appellant_ssn: correspondent_record.ssn,
      insurance_loan_number: case_record.bfpdnum,
      notification_date: normalize_vacols_date(case_record.bfdrodec),
      nod_date: normalize_vacols_date(case_record.bfdnod),
      soc_date: normalize_vacols_date(case_record.bfdsoc),
      form9_date: normalize_vacols_date(case_record.bfd19),
      ssoc_dates: ssoc_dates_from(case_record),
      hearing_request_type: VACOLS::Case::HEARING_REQUEST_TYPES[case_record.bfhr],
      video_hearing_requested: case_record.bfdocind == "X",
      hearing_requested: (case_record.bfhr == "1" || case_record.bfhr == "2"),
      hearing_held: !case_record.bfha.nil?,
      regional_office_key: case_record.bfregoff,
      certification_date: case_record.bf41stat,
      case_review_date: folder_record.tidktime,
      case_record: case_record,
      disposition: VACOLS::Case::DISPOSITIONS[case_record.bfdc],
      decision_date: normalize_vacols_date(case_record.bfddec),
      prior_decision_date: normalize_vacols_date(case_record.bfdpdcn),
      status: VACOLS::Case::STATUS[case_record.bfmpro],
      outcoding_date: normalize_vacols_date(folder_record.tioctime)
    )

    appeal
  end

  # :nocov:
  def self.issues(vacols_id)
    VACOLS::CaseIssue.descriptions(vacols_id).map do |issue_hash|
      Issue.load_from_vacols(issue_hash)
    end
  end

  def self.remands_ready_for_claims_establishment
    remands = MetricsService.record("VACOLS: remands_ready_for_claims_establishment",
                                    service: :vacols,
                                    name: "remands_ready_for_claims_establishment") do
      VACOLS::Case.remands_ready_for_claims_establishment
    end

    remands.map { |case_record| build_appeal(case_record) }
  end

  def self.amc_full_grants(outcoded_after:)
    full_grants = MetricsService.record("VACOLS:  amc_full_grants #{outcoded_after}",
                                        service: :vacols,
                                        name: "amc_full_grants") do
      VACOLS::Case.amc_full_grants(outcoded_after: outcoded_after)
    end

    full_grants.map { |case_record| build_appeal(case_record) }
  end
  # :nocov:

  def self.ssoc_dates_from(case_record)
    [
      case_record.bfssoc1,
      case_record.bfssoc2,
      case_record.bfssoc3,
      case_record.bfssoc4,
      case_record.bfssoc5
    ].map { |datetime| normalize_vacols_date(datetime) }.reject(&:nil?)
  end

  def self.folder_type_from(folder_record)
    if %w(Y 1 0).include?(folder_record.tivbms)
      "VBMS"
    elsif folder_record.tisubj == "Y"
      "VVA"
    else
      "Paper"
    end
  end

  # dates in VACOLS are incorrectly recorded as UTC.
  def self.normalize_vacols_date(datetime)
    return nil unless datetime
    utc_datetime = datetime.in_time_zone("UTC")

    Time.zone.local(
      utc_datetime.year,
      utc_datetime.month,
      utc_datetime.day
    )
  end

  def self.dateshift_to_utc(value)
    Time.utc(value.year, value.month, value.day, 0, 0, 0)
  end
  # :nocov:

  def self.establish_claim!(veteran_hash:, claim_hash:)
    @vbms_client ||= init_vbms_client

    request = VBMS::Requests::EstablishClaim.new(veteran_hash, claim_hash)

    send_and_log_request(veteran_hash[:file_number], request)
  end

  def self.update_vacols_after_dispatch!(appeal:, vacols_note: nil)
    VACOLS::Case.transaction do
      update_location_after_dispatch!(appeal: appeal)

      if vacols_note
        VACOLS::Note.create!(case_record: appeal.case_record,
                             text: vacols_note)
      end
    end
  end

  def self.update_location_after_dispatch!(appeal:)
    location = location_after_dispatch(appeal: appeal)

    appeal.case_record.update_vacols_location!(location)
  end

  # Determine VACOLS location desired after dispatching a decision
  def self.location_after_dispatch(appeal:)
    return if appeal.full_grant?

    return "54" if appeal.vamc?
    return "53" if appeal.national_cemetery_administration?
    return "50" if appeal.special_issues?

    # By default, we route the appeal to ARC
    "98"
  end

  def self.certify(appeal:, certification:)
    certification_date = AppealRepository.dateshift_to_utc Time.zone.now

    appeal.case_record.bfdcertool = certification_date
    appeal.case_record.bf41stat = certification_date

    appeal.case_record.bftbind = nil

    # rubocop:disable Style/IfInsideElse
    # Certification v2 - use the hearing preference that the user confirms.
    if FeatureToggle.enabled?(:certification_v2, user: RequestStore[:current_user])
      hearing_preference = VACOLS::Case::HEARING_PREFERENCE_TYPES_V2[certification.hearing_preference.to_sym]
      appeal.case_record.bfhr = hearing_preference[:vacols_value]
      appeal.case_record.bftbind = "X" if hearing_preference[:video_hearing]
    else
      appeal.case_record.bftbind = "X" if appeal.hearing_request_type == :travel_board
    end
    # rubocop:enable Style/IfInsideElse

    MetricsService.record("VACOLS: certify #{appeal.vacols_id}",
                          service: :vacols,
                          name: "certify") do
      appeal.case_record.save!
    end
  end

  # Reverses the certification of an appeal.
  # This is only used for test data setup, so it doesn't exist on Fakes::AppealRepository
  def self.uncertify(appeal)
    appeal.case_record.bftbind = nil
    appeal.case_record.bfdcertool = nil
    appeal.case_record.bf41stat = nil
    appeal.case_record.save!
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

  def self.clean_document(location)
    File.delete(location)
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

  def self.upload_document(vbms_id, upload_token, filepath)
    request = VBMS::Requests::UploadDocument.new(
      upload_token: upload_token,
      filepath: filepath
    )
    send_and_log_request(vbms_id, request)
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

  def self.vbms_config
    config = Rails.application.secrets.vbms.clone

    vbms_base_dir = config["env_dir"]
    vbms_env_name = config["env_name"]

    fail "missing vbms base dir" unless vbms_base_dir
    fail "missing vbms env name" unless vbms_env_name

    %w(keyfile saml key cacert cert).each do |file|
      vbms_file = config[file]
      fail "missing vbms file #{file}" unless vbms_file

      config[file] = File.join(vbms_base_dir, vbms_env_name, vbms_file)
    end

    config
  end

  def self.init_vbms_client
    VBMS::Client.from_env_vars(
      logger: VBMSCaseflowLogger.new,
      env_name: ENV["CONNECT_VBMS_ENV"]
    )
  end

  # :nocov:
end
