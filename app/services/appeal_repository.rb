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

  def self.find(vacols_id, _args = {})
    case_record = MetricsService.timer "loaded VACOLS case #{vacols_id}" do
      VACOLS::Case.includes(:folder, :correspondent).find(vacols_id)
    end

    create_appeal(case_record)
  end

  def self.ready_for_end_product(starttime)
    remands = MetricsService.timer "loaded remands in loc 97 from VACOLS" do
      VACOLS::CASE.remands_for_ep
    end

    fullgrants = MetricsService.timer "loaded full grants decided after #{starttime} from VACOLS" do
      VACOLS::CASE.fullgrants_for_ep(starttime)
    end

    (remands + fullgrants).map { |case_record| create_appeal(case_record) }
  end

  def self.create_appeal(case_record)
    appeal = Appeal.from_records(
      case_record: case_record,
      folder_record: case_record.folder,
      correspondent_record: case_record.correspondent
    )

    appeal.documents = fetch_documents_for(appeal).map do |vbms_document|
      Document.from_vbms_document(vbms_document)
    end

    appeal
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
    send_and_log_request(sanitized_id, request)
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
