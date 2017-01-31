require "vbms"

# :nocov:
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
# :nocov:

class AppealRepository
  ESTABLISH_CLAIM_VETERAN_ATTRIBUTES = %i(
    file_number sex first_name last_name ssn address_line1 address_line2
    address_line3 city state country zip_code
  ).freeze

  def self.load_vacols_data(appeal)
    case_record = MetricsService.timer "loaded VACOLS case #{appeal.vacols_id}" do
      VACOLS::Case.includes(:folder, :correspondent, :issues).find(appeal.vacols_id)
    end

    set_vacols_values(appeal: appeal, case_record: case_record)

    appeal
  end

  # :nocov:
  def self.load_vacols_data_by_vbms_id(appeal)
    case_records = MetricsService.timer "loaded VACOLS case #{appeal.vbms_id}" do
      VACOLS::Case.includes(:folder, :correspondent).find_by_bfcorlid(appeal.vbms_id)
    end

    fail MultipleAppealsByVBMSIDError if case_records.length > 1

    set_vacols_values(appeal: appeal, case_record: case_records.first)

    appeal
  end
  # :nocov:

  # TODO: consider persisting these records
  def self.build_appeal(case_record)
    appeal = Appeal.find_or_initialize_by(vacols_id: case_record.bfkey)
    set_vacols_values(appeal: appeal, case_record: case_record)
  end

  def self.map_issues(issue_records)
    issue_records.map do |issue|
      {
        description: issue[:issdesc],
        disposition: VACOLS::Issues::DISPOSITION_CODE[issue[:issdc]],
        program: issue[:issprog]
      }
    end
  end

  # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
  def self.set_vacols_values(appeal:, case_record:)
    correspondent_record = case_record.correspondent
    folder_record = case_record.folder
    issue_records = case_record.issues

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
      decision_date: normalize_vacols_date(case_record.bfddec),
      status: VACOLS::Case::STATUS[case_record.bfmpro],
      issues: map_issues(issue_records)
    )

    appeal
  end

  # :nocov:
  def self.remands_ready_for_claims_establishment
    remands = MetricsService.timer "loaded remands in loc 97 from VACOLS" do
      VACOLS::Case.remands_ready_for_claims_establishment
    end

    remands.map { |case_record| build_appeal(case_record) }
  end

  def self.amc_full_grants(decided_after:)
    full_grants = MetricsService.timer "loaded AMC full grants decided after #{decided_after} from VACOLS" do
      VACOLS::Case.amc_full_grants(decided_after: decided_after)
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

  def self.establish_claim!(appeal:, claim:)
    @vbms_client ||= init_vbms_client

    sanitized_id = appeal.sanitized_vbms_id
    raw_veteran_record = BGSService.new.fetch_veteran_info(sanitized_id)

    # Reduce keys in raw response down to what we specifically need for
    # establish claim
    veteran_record = parse_veteran_establish_claim_info(raw_veteran_record)

    request = VBMS::Requests::EstablishClaim.new(veteran_record, claim)
    end_product = send_and_log_request(sanitized_id, request)

    # Update VACOLS location
    # TODO(jd): In the future we whould specifically check this is an AMC EP
    # before updating the location to 98. For remands we need to set it to `50`
    # appeal.case_record.bfcurloc = '98'
    # MetricsService.timer "saved VACOLS case #{appeal.vacols_id}" do
    # appeal.case_record.save!
    # end

    # return end product so dispatch service can update the
    # task's outgoing_reference_id with end_product.claim_id
    end_product
  end

  def self.parse_veteran_establish_claim_info(veteran_record)
    veteran_record.select do |key, _|
      ESTABLISH_CLAIM_VETERAN_ATTRIBUTES.include?(key)
    end
  end

  def self.certify(appeal)
    certification_date = AppealRepository.dateshift_to_utc Time.zone.now

    appeal.case_record.bfdcertool = certification_date
    appeal.case_record.bf41stat = certification_date

    appeal.case_record.bftbind = "X" if appeal.hearing_type == :travel_board

    MetricsService.timer "saved VACOLS case #{appeal.vacols_id}" do
      appeal.case_record.save!
    end
  end

  # Reverses the certification of an appeal.
  # This is only used for test data setup, so it doesn't exist on Fakes::AppealRepository
  def self.uncertify(appeal)
    appeal.case_record.bfdcertool = nil
    appeal.case_record.bf41stat = nil
    appeal.case_record.save!
  end

  def self.upload_and_clean_document(appeal, form8)
    upload_document(appeal, form8)
    File.delete(form8.pdf_location)
  end

  def self.upload_document(appeal, uploadable_document)
    @vbms_client ||= init_vbms_client

    request = upload_documents_request(appeal, uploadable_document)

    send_and_log_request(appeal.vbms_id, request)
  end

  def self.upload_documents_request(appeal, uploadable_document)
    VBMS::Requests::UploadDocumentWithAssociations.new(
      appeal.sanitized_vbms_id,
      Time.zone.now,
      appeal.veteran_first_name,
      appeal.veteran_middle_initial,
      appeal.veteran_last_name,
      uploadable_document.document_type,
      uploadable_document.pdf_location,
      uploadable_document.document_type_id,
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

  def self.fetch_document_file(document)
    @vbms_client ||= init_vbms_client

    request = VBMS::Requests::FetchDocumentById.new(document.document_id)
    result = @vbms_client.send_request(request)
    result && result.content
  rescue => e
    Rails.logger.error "#{e.message}\n#{e.backtrace.join("\n")}"
    raise VBMS::ClientError
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

  # :nocov:
end
