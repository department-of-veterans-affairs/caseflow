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
    (document_records || {})[appeal.vbms_id] || @documents || []
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

    # return fake end product
    OpenStruct.new(claim_id: @end_product_claim_id || Generators::Appeal.generate_external_id)
  end
end
