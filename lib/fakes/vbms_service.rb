require "ostruct"

class VBMSCaseflowLogger
  def self.log(event, data)
    case event
    when :request
      status = data[:response_code]
      name = data[:request].class.name

      if status != 200
        Rails.logger.error(
          "VBMS HTTP Error #{status} " \
          "(#{name}) #{data[:response_body]}"
        )
      end
    end
  end
end

class Fakes::VBMSService
  class << self
    attr_accessor :document_records
    attr_accessor :end_product_claim_id
    attr_accessor :uploaded_form8, :uploaded_form8_appeal
    attr_accessor :manifest_vbms_fetched_at, :manifest_vva_fetched_at
    attr_accessor :contention_records
    attr_accessor :end_product_claim_ids_by_file_number
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def self.fetch_document_file(document)
    path =
      case document.vbms_document_id.to_i
      when 1
        File.join(Rails.root, "lib", "pdfs", "VA8.pdf")
      when 2
        File.join(Rails.root, "lib", "pdfs", "Formal_Form9.pdf")
      when 3
        File.join(Rails.root, "lib", "pdfs", "Informal_Form9.pdf")
      when 4
        File.join(Rails.root, "lib", "pdfs", "FakeDecisionDocument.pdf")
      when 5
        File.join(Rails.root, "lib", "pdfs", "megadoc.pdf")
      else
        file = File.join(Rails.root, "lib", "pdfs", "redacted", "#{document.vbms_document_id}.pdf")
        file = File.join(Rails.root, "lib", "pdfs", "KnockKnockJokes.pdf") unless File.exist?(file)
        file
      end
    IO.binread(path)
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def self.fetch_documents_for(appeal, _user = nil)
    # User is intentionally unused. It is meant to mock EfolderService.fetch_documents_for()
    fetched_at_format = "%FT%T.%LZ"
    {
      manifest_vbms_fetched_at: @manifest_vbms_fetched_at.try(:utc).try(:strftime, fetched_at_format),
      manifest_vva_fetched_at: @manifest_vva_fetched_at.try(:utc).try(:strftime, fetched_at_format),
      documents: (document_records || {})[appeal.vbms_id] || @documents || []
    }
  end

  def self.fetch_document_series_for(appeal)
    Document.where(file_number: appeal.vbms_id).map do |document|
      (0..document.id % 3).map do |index|
        OpenStruct.new(
          document_id: "#{document.vbms_document_id}#{(index > 0) ? index : ''}",
          version_id: "#{document.vbms_document_id}#{(index > 0) ? index : ''}",
          series_id: "TEST_SERIES_#{document.id}",
          version: index + 1,
          received_at: document.received_at
        )
      end
    end
  end

  def self.upload_document_to_vbms(appeal, form8)
    @uploaded_form8 = form8
    @uploaded_form8_appeal = appeal
  end

  def self.clean_document(_location)
    # noop
  end

  def self.establish_claim!(claim_hash:, veteran_hash:)
    Rails.logger.info("Submitting claim to VBMS...")
    Rails.logger.info("Veteran data:\n #{veteran_hash}")
    Rails.logger.info("Claim data:\n #{claim_hash}")

    self.end_product_claim_ids_by_file_number ||= {}

    # The id will either be:
    # A claim id set specifically for claims created on a specific file_number
    # A default claim id used for all created claims
    # A randomly generated id
    claim_id = end_product_claim_ids_by_file_number[veteran_hash[:file_number]] ||
               @end_product_claim_id ||
               Generators::Appeal.generate_external_id

    # return fake end product
    OpenStruct.new(claim_id: claim_id)
  end

  def self.fetch_contentions(claim_id:)
    (contention_records || {})[claim_id] || []
  end

  def self.create_contentions!(veteran_file_number:, claim_id:, contention_descriptions:)
    Rails.logger.info("Submitting contentions to VBMS...")
    Rails.logger.info("File number: #{veteran_file_number}")
    Rails.logger.info("Claim id:\n #{claim_id}")
    Rails.logger.info("Contention descriptions: #{contention_descriptions.inspect}")

    # Used to simulate a contention that fails to be created in VBMS
    contention_descriptions.delete("FAIL ME")

    # return fake list of contentions
    contention_descriptions.map do |description|
      Generators::Contention.build(text: description, claim_id: claim_id)
    end
  end
end
