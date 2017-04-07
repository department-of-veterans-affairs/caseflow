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
    attr_writer :documents
    attr_accessor :records
    attr_accessor :document_records
    attr_accessor :certified_appeal, :uploaded_form8, :uploaded_form8_appeal
    attr_accessor :end_product_claim_id
  end

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

  def self.certify(appeal)
    @certified_appeal = appeal
    VBMSCaseflowLogger.log(:request, response_code: 500)
  end

  def self.establish_claim!(claim:, appeal:)
    Rails.logger.info("Submitting claim to VBMS for appeal: #{appeal.id}")
    Rails.logger.info("Claim data:\n #{claim}")

    # return fake end product
    OpenStruct.new(claim_id: @end_product_claim_id)
  end

  def self.update_vacols_after_dispatch!(*)
  end

  def self.update_location_after_dispatch!(appeal:)
    return if appeal.full_grant?
  end

  def self.upload_document_to_vbms(appeal, form8)
    @uploaded_form8 = form8
    @uploaded_form8_appeal = appeal
  end

  def self.clean_document(_location)
    # noop
  end

  def self.load_vacols_data(appeal)
    return unless @records

    # timing a hash access is unnecessary but this adds coverage to MetricsService in dev mode
    record = MetricsService.record "load appeal #{appeal.vacols_id}" do
      @records[appeal.vacols_id] || fail(ActiveRecord::RecordNotFound)
    end

    fail VBMSError if !record.nil? && RAISE_VBMS_ERROR_ID == record[:vbms_id]

    # This is bad. I'm sorry
    record.delete(:vbms_id) if Rails.env.development?

    appeal.assign_from_vacols(record)
  end

  def self.load_vacols_data_by_vbms_id(appeal:, decision_type:)
    return unless @records

    Rails.logger.info("Load faked VACOLS data for appeal VBMS ID: #{appeal.vbms_id}")
    Rails.logger.info("Decision Type:\n#{decision_type}")

    # simulate VACOLS returning 2 appeals for a given vbms_id
    fail MultipleAppealsByVBMSIDError if RASIE_MULTIPLE_APPEALS_ERROR_ID == appeal[:vbms_id]

    # timing a hash access is unnecessary but this adds coverage to MetricsService in dev mode
    record = MetricsService.record "load appeal #{appeal.vacols_id}" do
      # TODO(jd): create a more dynamic setup
      @records.find { |_, r| r[:vbms_id] == appeal.vbms_id } || fail(ActiveRecord::RecordNotFound)
    end

    fail ActiveRecord::RecordNotFound unless record

    appeal.vacols_id = record[0]
    appeal.assign_from_vacols(record[1])
  end

  def self.fetch_documents_for(appeal)
    (document_records || {})[appeal.vbms_id] || @documents || []
  end

  def self.fetch_document_file(document)
    path =
      case document.vbms_document_id
      when "1"
        File.join(Rails.root, "lib", "pdfs", "VA8.pdf")
      when "2"
        File.join(Rails.root, "lib", "pdfs", "Formal_Form9.pdf")
      when "3"
        File.join(Rails.root, "lib", "pdfs", "Informal_Form9.pdf")
      when "4"
        File.join(Rails.root, "lib", "pdfs", "FakeDecisionDocument.pdf")
      else
        File.join(Rails.root, "lib", "pdfs", "KnockKnockJokes.pdf")
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

  def self.issues(_vacols_id)
    [
      VACOLS::Issue.format(
        "issprog" => "2",
        "issprog_label" => "Compensation",
        "isscode" => "10",
        "isscode_label" => "Service connection",
        "isslev1" => "20",
        "isslev1_label" => "All Others",
        "isslev2" => "30",
        "isslev2_label" => "Post-traumatic stress disorder",
        "isslev3" => nil,
        "isslev3_label" => nil,
        "issdc" => "Allowed"
      )
    ]
  end

  ## ALL SEED SCRIPTS BELOW THIS LINE ------------------------------
  # TODO: pull seed scripts into seperate object/module?

  def self.seed!
    return if Rails.env.test?

    seed_certification_data!
    seed_establish_claim_data!
  end

  def self.certification_documents
    [
      Generators::Document.build(type: "NOD"),
      Generators::Document.build(type: "SOC"),
      Generators::Document.build(type: "Form 9")
    ]
  end

  def self.establish_claim_documents
    certification_documents + [
      Generators::Document.build(type: "BVA Decision", received_at: 7.days.ago)
    ]
  end

  def self.establish_claim_multiple_decisions
    certification_documents + [
      Generators::Document.build(type: "BVA Decision", received_at: 7.days.ago),
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
end
