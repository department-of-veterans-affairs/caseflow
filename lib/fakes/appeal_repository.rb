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

# frozen_string_literal: true
class Fakes::AppealRepository
  class << self
    attr_accessor :document_records, :issue_records
    attr_accessor :end_product_claim_id
    attr_accessor :vacols_dispatch_update
    attr_accessor :location_updated_for
    attr_accessor :certified_appeal, :uploaded_form8, :uploaded_form8_appeal

    def records
      @records ||= {}
    end

    def clean!
      @records = {}
    end
  end

  READER_REDACTED_DOCS = [
    "VA 8 Certification of Appeal",
    "Supplemental Statement of the Case",
    "CAPRI",
    "Notice of Disagreement",
    "Rating Decision - Codesheet",
    "Rating Decision - Narrative",
    "Correspondence",
    "VA 21-526EZ, Fully Developed Claim",
    "STR - Medical",
    "Military Personnel Record",
    "Private Medical Treatment Record",
    "Map-D Development Letter",
    "Third Party Correspondence",
    "VA 9 Appeal to Board of Appeals",
    "Correspondence",
    "VA 21-4142 Authorization to Disclose Information to VA",
    "VA 21-4138 Statement in Support of Claim",
    "VA Memo"
  ].freeze

  RAISE_VBMS_ERROR_ID = "raise_vbms_error_id".freeze
  RASIE_MULTIPLE_APPEALS_ERROR_ID = "raise_multiple_appeals_error".freeze

  def self.new(vacols_id, default_attrs_method_name, overrides = {})
    # Dynamically call the specified class method name to obtain
    # the hash of defualt values eg:
    #   AppealRepository.new("123C", :appeal_ready_to_certify)
    default_attrs = send(default_attrs_method_name)
    attrs = default_attrs.merge(overrides) # merge in overrides

    appeal = Appeal.new(vacols_id: vacols_id)
    appeal.assign_from_vacols(attrs)
    appeal
  end

  def self.certify(appeal:, certification:)
    @certification = certification
    @certified_appeal = appeal
    VBMSCaseflowLogger.log(:request, response_code: 500)
  end

  def self.establish_claim!(claim_hash:, veteran_hash:)
    Rails.logger.info("Submitting claim to VBMS...")
    Rails.logger.info("Veteran data:\n #{veteran_hash}")
    Rails.logger.info("Claim data:\n #{claim_hash}")

    # return fake end product
    OpenStruct.new(claim_id: @end_product_claim_id || Generators::Appeal.generate_external_id)
  end

  def self.update_vacols_after_dispatch!(appeal:, vacols_note:)
    self.vacols_dispatch_update = { appeal: appeal, vacols_note: vacols_note }
  end

  def self.update_location_after_dispatch!(appeal:)
    return if appeal.full_grant?
    self.location_updated_for = appeal
  end

  def self.upload_document_to_vbms(appeal, form8)
    @uploaded_form8 = form8
    @uploaded_form8_appeal = appeal
  end

  def self.clean_document(_location)
    # noop
  end

  def self.raise_vbms_error_if_necessary(record)
    fail VBMS::ClientError if !record.nil? && RAISE_VBMS_ERROR_ID == record[:vbms_id]
  end

  def self.load_vacols_data(appeal)
    # timing a hash access is unnecessary but this adds coverage to MetricsService in dev mode
    record = MetricsService.record "load appeal #{appeal.vacols_id}" do
      records[appeal.vacols_id]
    end

    return false unless record

    # clone this since we mutate it later
    record = record.dup

    raise_vbms_error_if_necessary(record)

    appeal.assign_from_vacols(record)

    true
  end

  def self.load_vacols_data_by_vbms_id(appeal:, decision_type:)
    Rails.logger.info("Load faked VACOLS data for appeal VBMS ID: #{appeal.vbms_id}")
    Rails.logger.info("Decision Type:\n#{decision_type}")

    # simulate VACOLS returning 2 appeals for a given vbms_id
    fail Caseflow::Error::MultipleAppealsByVBMSID if RASIE_MULTIPLE_APPEALS_ERROR_ID == appeal[:vbms_id]

    # timing a hash access is unnecessary but this adds coverage to MetricsService in dev mode
    record = MetricsService.record "load appeal #{appeal.vacols_id}" do
      # TODO(jd): create a more dynamic setup
      records.find { |_, r| r[:vbms_id] == appeal.vbms_id }
    end

    return false unless record

    # clone this in case it accidentally gets mutated later
    record = record.dup

    appeal.vacols_id = record[0]
    appeal.assign_from_vacols(record[1])
  end

  def self.fetch_documents_for(appeal)
    (document_records || {})[appeal.vbms_id] || @documents || []
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
      else
        file = File.join(Rails.root, "lib", "pdfs", "redacted", "#{document.vbms_document_id}.pdf")
        file = File.join(Rails.root, "lib", "pdfs", "KnockKnockJokes.pdf") unless File.exist?(file)
        file
      end
    IO.binread(path)
  end

  def self.remands_ready_for_claims_establishment
    []
  end

  def self.amc_full_grants(*)
    []
  end

  def self.uncertify(_appeal)
    # noop
  end

  def self.issues(vacols_id)
    (issue_records || {})[vacols_id] || []
  end

  ## ALL SEED SCRIPTS BELOW THIS LINE ------------------------------
  # TODO: pull seed scripts into seperate object/module?

  def self.seed!
    return if Rails.env.test?

    seed_certification_data!
    seed_establish_claim_data!
    seed_reader_data!
  end

  def self.certification_documents
    [
      Generators::Document.build(type: "NOD", category_procedural: true),
      Generators::Document.build(type: "SOC"),
      Generators::Document.build(type: "Form 9", category_medical: true)
    ]
  end

  def self.establish_claim_documents
    certification_documents + [
      Generators::Document.build(type: "BVA Decision", received_at: 7.days.ago, category_other: true)
    ]
  end

  def self.establish_claim_multiple_decisions
    establish_claim_documents + [
      Generators::Document.build(type: "BVA Decision", received_at: 8.days.ago)
    ]
  end

  def self.seed_establish_claim_data!
    # Make every other case have two decision documents
    50.times.each do |i|
      Generators::Appeal.build(
        vacols_id: "vacols_id#{i}",
        vbms_id: "vbms_id#{i}",
        vacols_record: [:full_grant_decided, :partial_grant_decided, :remand_decided][i % 3],
        documents: i.even? ? establish_claim_documents : establish_claim_multiple_decisions
      )
    end
  end

  def self.seed_appeal_ready_to_certify!
    nod, soc, form9 = certification_documents

    Generators::Appeal.build(
      vacols_id: "123C",
      vbms_id: "1111",
      vacols_record: {
        template: :ready_to_certify,
        nod_date: nod.received_at,
        soc_date: soc.received_at,
        form9_date: form9.received_at
      },
      documents: [nod, soc, form9]
    )
  end

  def self.seed_appeal_mismatched_documents!
    nod, soc, form9 = certification_documents

    Generators::Appeal.build(
      vacols_id: "456C",
      vacols_record: {
        template: :ready_to_certify,
        nod_date: nod.received_at,
        soc_date: soc.received_at,
        form9_date: form9.received_at
      },
      documents: [nod, soc]
    )
  end

  def self.seed_appeal_already_certified!
    Generators::Appeal.build(
      vacols_id: "789C",
      vacols_record: :certified
    )
  end

  def self.seed_appeal_ready_to_certify_with_informal_form9!
    nod, soc, form9 = certification_documents

    form9.vbms_document_id = "3"

    Generators::Appeal.build(
      vacols_id: "124C",
      vbms_id: "1112",
      vacols_record: {
        template: :ready_to_certify,
        nod_date: nod.received_at,
        soc_date: soc.received_at,
        form9_date: form9.received_at
      },
      documents: [nod, soc, form9]
    )
  end

  def self.seed_appeal_raises_vbms_error!
    nod, soc, form9 = certification_documents

    Generators::Appeal.build(
      vacols_id: "000ERR",
      vbms_id: Fakes::AppealRepository::RAISE_VBMS_ERROR_ID,
      vacols_record: {
        template: :ready_to_certify,
        nod_date: nod.received_at,
        soc_date: soc.received_at,
        form9_date: form9.received_at
      },
      documents: [nod, soc, form9]
    )
  end

  def self.seed_appeal_not_ready!
    Generators::Appeal.build(
      vacols_id: "001ERR",
      vacols_record: :not_ready_to_certify
    )
  end

  def self.seed_certification_data!
    seed_appeal_ready_to_certify!
    seed_appeal_mismatched_documents!
    seed_appeal_already_certified!
    seed_appeal_ready_to_certify_with_informal_form9!
    seed_appeal_raises_vbms_error!
    seed_appeal_not_ready!
  end

  def self.static_reader_documents
    [
      Generators::Document.build(vbms_document_id: 1, type: "NOD", category_procedural: true),
      Generators::Document.build(vbms_document_id: 2, type: "SOC", category_medical: true),
      Generators::Document.build(vbms_document_id: 3, type: "Form 9",
                                 category_medical: true, category_procedural: true),
      Generators::Document.build(
        vbms_document_id: 4,
        type: "This is a very long document type let's see what it does to the UI!",
        received_at: 7.days.ago,
        category_other: true),
      Generators::Document.build(vbms_document_id: 5, type: "BVA Decision", received_at: 8.days.ago,
                                 category_medical: true, category_procedural: true, category_other: true)
    ]
  end

  def self.random_reader_documents(num_documents)
    (0..num_documents).to_a.reduce([]) do |acc, number|
      acc << Generators::Document.build(
        vbms_document_id: number,
        type: Caseflow::DocumentTypes::TYPES.values[rand(Caseflow::DocumentTypes::TYPES.length)],
        category_procedural: rand(10) == 1,
        category_medical: rand(10) == 1,
        category_other: rand(10) == 1)
    end
  end

  def self.redacted_reader_documents
    READER_REDACTED_DOCS.each_with_index.map do |doc_type, index|
      Generators::Document.build(
        vbms_document_id: (100 + index),
        type: doc_type
      )
    end
  end

  # rubocop:disable Metrics/MethodLength
  def self.seed_reader_data!
    FeatureToggle.enable!(:reader)

    Generators::Appeal.build(
      vacols_id: "reader_id1",
      vbms_id: "reader_id1",
      vacols_record: {
        template: :ready_to_certify,
        veteran_first_name: "Joe",
        veteran_last_name: "Smith"
      },
      documents: static_reader_documents
    )
    Generators::Appeal.build(
      vacols_id: "reader_id2",
      vbms_id: "reader_id2",
      vacols_record: {
        template: :ready_to_certify,
        veteran_first_name: "Joe",
        veteran_last_name: "Smith"
      },
      documents: random_reader_documents(200)
    )
    Generators::Appeal.build(
      vacols_id: "reader_id3",
      vbms_id: "reader_id3",
      vacols_record: {
        template: :ready_to_certify,
        veteran_first_name: "Joe",
        veteran_last_name: "Smith"
      },
      documents: redacted_reader_documents
    )
  end
end
