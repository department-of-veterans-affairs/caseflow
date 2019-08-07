# frozen_string_literal: true

class ExternalApi::VbmsDocumentsForAppeal
  def initialize(file_number:, vbms_client: init_vbms_client, bgs_client: init_bgs_client)
    @file_number = file_number
    @vbms_client = vbms_client
    @bgs_client = bgs_client
  end

  def fetch
    DBService.release_db_connections

    begin
      fetch_veteran_file_number_docs
    rescue VBMS::FilenumberDoesNotExist
      raise if bgs_claim_number_nil_or_same_as_veteran_file_number?

      fetch_bgs_claim_number_docs
    end

    Rails.logger.info("Document list length: #{documents.length}")

    result_hash
  end

  private

  attr_reader :file_number, :vbms_client, :bgs_client, :documents

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

  def fetch_veteran_file_number_docs
    @documents = ExternalApi::VBMSRequest.new(
      client: vbms_client,
      request: veteran_file_number_docs_request,
      id: file_number
    ).call
  end

  def bgs_claim_number_nil_or_same_as_veteran_file_number?
    bgs_claim_number.nil? || bgs_claim_number == file_number
  end

  def fetch_bgs_claim_number_docs
    @documents = ExternalApi::VBMSRequest.new(
      client: vbms_client,
      request: bgs_claim_number_docs_request,
      id: bgs_claim_number
    ).call
  end

  def result_hash
    {
      manifest_vbms_fetched_at: nil,
      manifest_vva_fetched_at: nil,
      documents: DocumentsFromVbmsDocuments.new(documents: documents, file_number: file_number).call
    }
  end

  def bgs_claim_number
    @bgs_claim_number ||= bgs_client.fetch_veteran_info(file_number)[:claim_number]
  end

  def veteran_file_number_docs_request
    VBMS::Requests::FindDocumentVersionReference.new(file_number)
  end

  def bgs_claim_number_docs_request
    VBMS::Requests::FindDocumentVersionReference.new(bgs_claim_number)
  end
end
