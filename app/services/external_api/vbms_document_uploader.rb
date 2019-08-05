# frozen_string_literal: true

class ExternalApi::VbmsDocumentUploader
  def initialize(file_number:, document:, vbms_client: init_vbms_client, bgs_client: init_bgs_client)
    @file_number = file_number
    @document = document
    @vbms_client = vbms_client
    @bgs_client = bgs_client
  end

  def call
    begin
      upload_document_using_veteran_file_number
    rescue VBMSError::FilenumberDoesNotExist
      raise if bgs_claim_number_nil_or_same_as_veteran_file_number?

      upload_document_using_bgs_claim_number
    end
  end

  private

  attr_reader :file_number, :document, :vbms_client, :bgs_client, :upload_token

  def init_vbms_client
    VBMS::Client.from_env_vars(
      logger: VBMSCaseflowLogger.new,
      env_name: ENV["CONNECT_VBMS_ENV"],
      use_forward_proxy: FeatureToggle.enabled?(:vbms_forward_proxy)
    )
  end

  def init_bgs_client
    ExternalApi::BGSService.new
  end

  def bgs_claim_number_nil_or_same_as_veteran_file_number?
    bgs_claim_number.nil? || bgs_claim_number == file_number
  end

  def bgs_claim_number
    @bgs_claim_number ||= bgs_client.fetch_veteran_info(file_number)[:claim_number]
  end

  def upload_document_using_veteran_file_number
    response = initialize_upload
    @upload_token = response.upload_token
    upload_document
  end

  def upload_document_using_bgs_claim_number
    @file_number = bgs_claim_number
    response = initialize_upload
    @upload_token = response.upload_token
    upload_document
  end

  def initialize_upload
    request = VBMS::Requests::InitializeUpload.new(
      content_hash: content_hash,
      filename: filename,
      file_number: file_number,
      va_receive_date: Time.zone.now,
      doc_type: document.document_type_id,
      source: document.source,
      subject: document.document_type,
      new_mail: true
    )
    send_and_log_request(request)
  end

  def upload_document
    request = VBMS::Requests::UploadDocument.new(
      upload_token: upload_token,
      filepath: filepath
    )
    send_and_log_request(request)
  end

  def content_hash
    Digest::SHA1.hexdigest(File.read(filepath))
  end

  def filename
    SecureRandom.uuid + File.basename(filepath)
  end

  def filepath
    @filepath ||= document.pdf_location
  end

  def send_and_log_request(request)
    ExternalApi::VBMSRequest.new(
      client: vbms_client,
      request: request,
      id: file_number
    ).call
  end
end
