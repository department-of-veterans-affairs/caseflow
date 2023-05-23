# frozen_string_literal: true

require "ostruct"
require "csv"

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
  HOLD_REQUEST_TIMEOUT_SECONDS = 2

  class << self
    attr_accessor :document_records
    attr_accessor :end_product_claim_id
    attr_accessor :uploaded_form8, :uploaded_form8_appeal
    attr_accessor :manifest_vbms_fetched_at, :manifest_vva_fetched_at
    attr_accessor :end_product_claim_ids_by_file_number
  end

  def self.load_vbms_ids_mappings
    file_path = Rails.root.join("local", "vacols", "vbms_setup.csv")

    return if !Rails.env.development? || !File.exist?(file_path) || @load_vbms_ids_mappings

    @load_vbms_ids_mappings = true
    @document_records ||= {}
    CSV.foreach(file_path, headers: true) do |row|
      row_hash = row.to_h
      vbms_id = row_hash["vbms_id"].gsub(/[^0-9]/, "")
      @document_records[vbms_id] = Fakes::Data::AppealData.document_mapping[row_hash["documents"]]
      (@document_records[vbms_id] || []).each { |document| document.write_attribute(:file_number, vbms_id) }
    end
  end

  def self.hold_request!
    @hold_request = true
  end

  def self.resume_request!
    @hold_request = false
  end

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

  def self.document_count(veteran_file_number, _user = nil)
    docs = (document_records || {})[veteran_file_number] || @documents || []
    docs.length
  end

  def self.fetch_documents_for(appeal, _user = nil)
    load_vbms_ids_mappings

    # User is intentionally unused. It is meant to mock EfolderService.fetch_documents_for()
    fetched_at_format = "%FT%T.%LZ"
    {
      manifest_vbms_fetched_at: @manifest_vbms_fetched_at.try(:utc).try(:strftime, fetched_at_format),
      manifest_vva_fetched_at: @manifest_vva_fetched_at.try(:utc).try(:strftime, fetched_at_format),
      documents: (document_records || {})[appeal.veteran_file_number] || @documents || []
    }
  end

  def self.fetch_document_series_for(appeal)
    Document.where(file_number: appeal.veteran_file_number).map do |document|
      (0..document.id % 3).map do |index|
        OpenStruct.new(
          document_id: "#{document.vbms_document_id}#{(index > 0) ? index : ''}",
          series_id: "TEST_SERIES_#{document.id}",
          version: index + 1,
          received_at: document.received_at
        )
      end
    end
  end

  def self.update_document_in_vbms(appeal, uploadable_document, prev_version_ref_id)
    @appeal = appeal
    @updated_document = uploadable_document
    @prev_version_ref_id = prev_version_ref_id
  end

  def self.upload_document_to_vbms(appeal, form8)
    @uploaded_form8 = form8
    @uploaded_form8_appeal = appeal
  end

  def self.upload_document_to_vbms_veteran(file_number, form8)
    @uploaded_form8 = form8
    @veteran_file_number = file_number
  end

  def self.clean_document(_location)
    # noop
  end

  def self.establish_claim!(claim_hash:, veteran_hash:, user:)
    (HOLD_REQUEST_TIMEOUT_SECONDS * 100).times do
      break unless @hold_request

      sleep 0.01
    end

    Rails.logger.info("Submitting claim to VBMS...")
    Rails.logger.info("Veteran data:\n #{veteran_hash}")
    Rails.logger.info("Claim data:\n #{claim_hash}")
    Rails.logger.info("User:\n #{user.inspect}")

    self.end_product_claim_ids_by_file_number ||= {}

    # The id will either be:
    # A claim id set specifically for claims created on a specific file_number
    # A default claim id used for all created claims
    # A randomly generated id
    claim_id = end_product_claim_ids_by_file_number[veteran_hash[:file_number]] ||
               @end_product_claim_id ||
               Generators::Random.external_id

    # return fake end product
    generate_end_product_for_claim(veteran_hash: veteran_hash, claim_hash: claim_hash, claim_id: claim_id)
  end

  def self.generate_end_product_for_claim(veteran_hash:, claim_hash:, claim_id:)
    Generators::EndProduct.build(
      veteran_file_number: veteran_hash[:file_number],
      bgs_attrs: {
        benefit_claim_id: claim_id,
        claim_receive_date: claim_hash[:date].to_formatted_s(:short_date),
        end_product_type_code: claim_hash[:end_product_modifier],
        claim_type_code: claim_hash[:end_product_code]
      }
    )
  end

  def self.get_dispositions!(claim_id:)
    Fakes::BGSService.end_product_store.inflated_dispositions_for(claim_id) || []
  end

  def self.fetch_contentions(claim_id:)
    Fakes::BGSService.end_product_store.inflated_contentions_for(claim_id) || []
  end

  def self.create_contentions!(veteran_file_number:, claim_id:, contentions:, claim_date:, user:)
    Rails.logger.info("Submitting contentions to VBMS...")
    Rails.logger.info("File number: #{veteran_file_number}")
    Rails.logger.info("Claim id: #{claim_id}")
    Rails.logger.info("Contentions: #{contentions.inspect}")
    Rails.logger.info("Claim_date: #{claim_date}")
    Rails.logger.info("User:\n #{user.inspect}")

    # Used to simulate a contention that fails to be created in VBMS
    contentions.delete(description: "FAIL ME")

    # generate new contentions and return list of all contentions on the claim.
    contentions.each do |contention|
      Generators::Contention.build(text: contention[:description],
                                   claim_id: claim_id, type_code: contention[:contention_type])
    end
    Fakes::BGSService.end_product_store.inflated_contentions_for(claim_id)
  end

  def self.associate_rating_request_issues!(claim_id:, rating_issue_contention_map:)
    Rails.logger.info("Submitting rated issues to VBMS...")
    Rails.logger.info("Claim id:\n #{claim_id}")
    Rails.logger.info("Rating issue contention map: #{rating_issue_contention_map.inspect}")

    true
  end

  def self.remove_contention!(contention)
    Rails.logger.info("Submitting remove contention request to VBMS...")
    Rails.logger.info("Contention: #{contention.inspect}")

    Fakes::BGSService.end_product_store.remove_contention(contention)

    true
  end

  def self.update_contention!(contention)
    Rails.logger.info("Submitting updated contention request to VBMS...")
    Rails.logger.info("Contention: #{contention.inspect}")

    Fakes::BGSService.end_product_store.update_contention(contention)

    contention
  end

  # Used in test to clean fake VBMS state.
  def self.clean!
    self.document_records = nil
    self.end_product_claim_id = nil
    self.uploaded_form8 = nil
    self.uploaded_form8_appeal = nil
    self.manifest_vbms_fetched_at = nil
    self.manifest_vva_fetched_at = nil
    self.end_product_claim_ids_by_file_number = nil
  end
end
