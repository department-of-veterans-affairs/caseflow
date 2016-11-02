require "vbms"

class CaseflowLogger
  def log(event, data)
    case event
    when :request
      if data[:response_code] != 200
        Rails.logger.error(
          "VBMS HTTP Error #{data[:response_code]} " \
          "(#{data[:request].class.name}) #{data[:response_body]}"
        )
      end
    end
  end
end

class AppealRepository
  FORM_8_DOC_TYPE_ID = 178

  def self.load_vacols_data(appeal)
    case_record = MetricsService.timer "loaded VACOLS case #{vacols_id}" do
      VACOLS::Case.includes(:folder, :correspondent).find(appeal.vacols_id)
    end

    set_vacols_values(appeal: appeal, case_record: case_record)

    appeal
  end

  #TODO: consider persisting these records
  def self.build_appeal(case_record)
    AppealRepository.set_vacols_values(Appeal.new, case_record)
  end

  def self.set_vacols_values(appeal:, case_record:)
    correspondent_record = case_record.correspondent
    folder_record = case_record.folder

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    appeal.set_from_vacols(
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
      insurance_loan_number: case_record.bfpdnum,
      notification_date: normalize_vacols_date(case_record.bfdrodec),
      nod_date: normalize_vacols_date(case_record.bfdnod),
      soc_date: normalize_vacols_date(case_record.bfdsoc),
      form9_date: normalize_vacols_date(case_record.bfd19),
      ssoc_dates: ssoc_dates_from(case_record),
      hearing_type: VACOLS::Case::HEARING_TYPES[case_record.bfha],
      hearing_requested: (case_record.bfhr == "1" || case_record.bfhr == "2"),
      hearing_held: !case_record.bfha.nil?,
      regional_office_key: case_record.bfregoff,
      certification_date: case_record.bf41stat,
      case_record: case_record,
      disposition: VACOLS::Case::DISPOSITIONS[case_record.bfdc],
      decision_date: normalize_vacols_date(case_record.bfddec)
    )

    appeal
  end

  def self.remands_ready_for_claims_establishment
    remands = MetricsService.timer "loaded remands in loc 97 from VACOLS" do
      VACOLS::CASE.remands_ready_for_claims_establishment
    end

    remands.map { |case_record| build_appeal(case_record) }
  end

  def self.amc_full_grants(decided_after:)
    full_grants = MetricsService.timer "loaded AMC full grants decided after #{decided_after} from VACOLS" do
      VACOLS::CASE.amc_full_grants(decided_after)
    end

    full_grants.map { |case_record| build_appeal(case_record) }
  end


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

  def self.certify(appeal)
    certification_date = AppealRepository.dateshift_to_utc Time.zone.now

    appeal.case_record.bfdcertool = certification_date
    appeal.case_record.bf41stat = certification_date

    appeal.case_record.bftbind = "X" if appeal.hearing_type == :travel_board

    MetricsService.timer "saved VACOLS case #{appeal.vacols_id}" do
      appeal.case_record.save!
    end

    upload_form8_for(appeal)
  end

  def self.upload_form8_for(appeal)
    @vbms_client ||= init_vbms_client

    form8 = Form8.from_appeal(appeal)
    request = upload_documents_request(appeal, form8)

    send_and_log_request(appeal.vbms_id, request)

    File.delete(form8.pdf_location)
  end

  def self.upload_documents_request(appeal, form8)
    VBMS::Requests::UploadDocumentWithAssociations.new(
      appeal.sanitized_vbms_id,
      Time.zone.now,
      appeal.veteran_first_name,
      appeal.veteran_middle_initial,
      appeal.veteran_last_name,
      "Form 8",
      form8.pdf_location,
      FORM_8_DOC_TYPE_ID,
      "VACOLS",
      true
    )
  end

  def self.send_and_log_request(vbms_id, request)
    MetricsService.timer "sent VBMS request #{request.class} for #{vbms_id}" do
      @vbms_client.send_request(request)
    end

  # rethrow as application-level error
  rescue VBMS::ClientError
    raise VBMSError
  end

  def self.fetch_documents_for(appeal)
    @vbms_client ||= init_vbms_client

    sanitized_id = appeal.sanitized_vbms_id
    request = VBMS::Requests::ListDocuments.new(sanitized_id)
    documents = send_and_log_request(sanitized_id, request)

    appeal.documents = documents.map do |vbms_document|
      Document.from_vbms_document(vbms_document)
    end

    appeal
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
      logger: CaseflowLogger.new,
      env_name: ENV["CONNECT_VBMS_ENV"]
    )
  end
end
