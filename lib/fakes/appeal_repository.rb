require "ostruct"

class VBMSCaseflowLogger
  def self.log(event, data)
    case event
    when :request
      status = data[:response_code]
      if status != 200
        PrometheusService.completed_vbms_requests.increment({ status: status })

        Rails.logger.error(
          "VBMS HTTP Error #{status} " \
          "(#{data[:request].class.name}) #{data[:response_body]}"
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
    VBMSCaseflowLogger.log(:request, {response_code: 500})
  end

  def self.establish_claim!(claim:, appeal:)
    p "Submitting claim to VBMS for appeal: #{appeal.id}"
    p "Claim data:\n", claim

    # return fake end product
    OpenStruct.new(claim_id: @end_product_claim_id)
  end

  def self.update_location_after_dispatch!(*)
  end

  def self.upload_and_clean_document(appeal, form8)
    @uploaded_form8 = form8
    @uploaded_form8_appeal = appeal
  end

  def self.load_vacols_data(appeal)
    return unless @records

    # timing a hash access is unnecessary but this adds coverage to MetricsService in dev mode
    record = MetricsService.timer "load appeal #{appeal.vacols_id}" do
      @records[appeal.vacols_id] || fail(ActiveRecord::RecordNotFound)
    end

    # RAISE_VACOLS_NOT_FOUND_ID == record[:vacols_id]
    fail VBMSError if !record.nil? && RAISE_VBMS_ERROR_ID == record[:vbms_id]

    appeal.assign_from_vacols(record)
  end

  def self.load_vacols_data_by_vbms_id(appeal:, decision_type:)
    return unless @records

    p "Load faked VACOLS data for appeal VBMS ID: #{appeal.vbms_id}"
    p "Decision Type:\n", decision_type

    # simulate VACOLS returning 2 appeals for a given vbms_id
    fail MultipleAppealsByVBMSIDError if RASIE_MULTIPLE_APPEALS_ERROR_ID == appeal[:vbms_id]

    # timing a hash access is unnecessary but this adds coverage to MetricsService in dev mode
    record = MetricsService.timer "load appeal #{appeal.vacols_id}" do
      # TODO(jd): create a more dynamic setup
      @records.find { |_, r| r[:vbms_id] == appeal.vbms_id } || fail(ActiveRecord::RecordNotFound)
    end

    fail ActiveRecord::RecordNotFound unless record

    appeal.vacols_id = record[0]
    appeal.assign_from_vacols(record[1])
  end

  def self.fetch_documents_for(appeal)
    vbms_record = @records[appeal.vbms_id]
    if vbms_record
      appeal.documents = vbms_record[:documents]
      return
    end
    appeal.documents = @documents || []
  end

  def self.fetch_document_file(document)
    path =
      case document.vbms_document_id
      when "1"
        File.join(Rails.root, "lib", "pdfs", "VA8.pdf")
      when "2"
        File.join(Rails.root, "lib", "pdfs", "VA9.pdf")
      when "3"
        File.join(Rails.root, "lib", "pdfs", "FakeDecisionDocument.pdf")
      else
        File.join(Rails.root, "lib", "pdfs", "KnockKnockJokes.pdf")
      end
    IO.binread(path)
  end

  def self.remands_ready_for_claims_establishment
    [@records["321C"]]
  end

  def self.amc_full_grants(decided_after:)
    [@records["654C"]].select { |appeal| appeal.decision_date > decided_after }
  end

  def self.uncertify(_appeal)
    # noop
  end

  # TODO(mdbenjam): refactor this to map appeals to VACOLS ids?
  # rubocop:disable Metrics/MethodLength
  def self.appeal_ready_to_certify
    {
      vbms_id: "VBMS-ID",
      type: VACOLS::Case::TYPES["1"], # Original
      file_type: "VBMS",
      representative: VACOLS::Case::REPRESENTATIVES["F"][:full_name], # Military Order of the Purple Heart
      veteran_first_name: "Davy",
      veteran_middle_initial: "Q",
      veteran_last_name: "Crockett",
      appellant_first_name: "Susie",
      appellant_middle_initial: "X",
      appellant_last_name: "Crockett",
      appellant_relationship: "Daughter",
      insurance_loan_number: "1234", # Check that this doesn't actually come through as a number type
      notification_date: 1.day.ago,
      nod_date: 3.days.ago,
      soc_date: Date.new(1987, 9, 6),
      form9_date: 1.day.ago,
      hearing_type: VACOLS::Case::HEARING_TYPES["1"], # Central office
      regional_office_key: "DSUSER",
      documents: [nod_document, soc_document, form9_document],
      disposition: VACOLS::Case::DISPOSITIONS["4"], # Denied
      status: VACOLS::Case::STATUS["ADV"] # Advance
    }
  end

  def self.appeal_mismatched_nod
    {
      type: "Original",
      file_type: "VBMS",
      vbms_id: "VBMS-ID",
      representative: "Military Order of the Purple Heart",
      nod_date: 4.days.ago,
      soc_date: Date.new(1987, 9, 6),
      form9_date: 1.day.ago,
      notification_date: 1.day.ago,
      documents: [nod_document, soc_document, form9_document],
      veteran_first_name: "Davy",
      veteran_last_name: "Crockett",
      appellant_first_name: "Susie",
      appellant_last_name: "Crockett",
      appellant_relationship: "Daughter",
      regional_office_key: "DSUSER"
    }
  end

  def self.appeal_mismatched_ssoc
    {
      type: "Original",
      file_type: "VBMS",
      representative: "Military Order of the Purple Heart",
      nod_date: 3.days.ago,
      soc_date: Date.new(1987, 9, 6),
      form9_date: 1.day.ago,
      ssoc_dates: [6.days.from_now, 7.days.from_now],
      documents: [nod_document, soc_document, form9_document],
      veteran_first_name: "Davy",
      veteran_last_name: "Crockett",
      appellant_first_name: "Susie",
      appellant_last_name: "Crockett",
      appellant_relationship: "Daughter",
      regional_office_key: "DSUSER"
    }
  end

  def self.appeal_mismatched_docs
    {
      type: "Original",
      file_type: "VBMS",
      representative: "Military Order of the Purple Heart",
      nod_date: 1.day.ago,
      soc_date: Date.new(1987, 9, 7),
      form9_date: 1.day.ago,
      ssoc_dates: [6.days.from_now, 7.days.from_now],
      documents: [nod_document, soc_document],
      veteran_first_name: "Davy",
      veteran_last_name: "Crockett",
      appellant_first_name: "Susie",
      appellant_last_name: "Crockett",
      appellant_relationship: "Daughter",
      regional_office_key: "DSUSER"
    }
  end

  def self.appeal_already_certified
    {
      type: :original,
      file_type: :vbms,
      vbms_id: "VBMS-ID",
      representative: "Military Order of the Purple Heart",
      nod_date: 3.days.ago,
      soc_date: Date.new(1987, 9, 6),
      certification_date: 1.day.ago,
      form9_date: 1.day.ago,
      documents: [nod_document, soc_document, form9_document],
      veteran_first_name: "Davy",
      veteran_last_name: "Crockett",
      appellant_first_name: "Susie",
      appellant_last_name: "Crockett",
      appellant_relationship: "Daughter",
      regional_office_key: "DSUSER"
    }
  end

  def self.appeal_remand_decided
    {
      vbms_id: "REMAND_VBMS_ID",
      type: "Original",
      status: "Remand",
      disposition: "Remanded",
      decision_date: 7.days.ago,
      veteran_first_name: "Davy",
      veteran_last_name: "Crockett",
      appellant_first_name: "Susie",
      appellant_last_name: "Crockett",
      appellant_relationship: "Daughter",
      regional_office_key: "RO13"
    }
  end

  def self.appeal_partial_grant_decided(vbms_id: "REMAND_VBMS_ID", missing_decision: false)
    {
      vbms_id: vbms_id,
      type: "Original",
      status: "Remand",
      disposition: "Allowed",
      decision_date: 7.days.ago,
      veteran_first_name: "Davy",
      veteran_last_name: "Crockett",
      appellant_first_name: "Susie",
      appellant_last_name: "Crockett",
      appellant_relationship: "Daughter",
      documents: missing_decision ? [] : [decision_document]
    }
  end

  def self.appeal_full_grant_decided
    {
      vbms_id: "FULLGRANT_VBMS_ID",
      type: "Post Remand",
      status: "Complete",
      disposition: "Allowed",
      decision_date: 7.days.ago,
      veteran_first_name: "Davy",
      veteran_last_name: "Crockett",
      appellant_first_name: "Susie",
      appellant_last_name: "Crockett",
      appellant_relationship: "Daughter",
      regional_office_key: "RO13",
      documents: [nod_document, soc_document, form9_document, decision_document]
    }
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

  def self.first_names
    %w(George John Thomas James Andrew Martin)
  end

  def self.last_names
    %w(Washington Adams Jefferson Madison Jackson VanBuren)
  end

  def self.appeals_for_tasks(index)
    appeal_full_grant_decided.merge(
      veteran_last_name: last_names[index % last_names.length],
      veteran_first_name: first_names[index % first_names.length]
    )
  end

  def self.appeal_raises_vbms_error
    a = appeal_ready_to_certify
    a[:vbms_id] = RAISE_VBMS_ERROR_ID
    a
  end

  def self.appeal_missing_data
    a = appeal_ready_to_certify
    a[:form9_date] = nil
    a
  end

  def self.nod_document
    Document.from_vbms_document(
      OpenStruct.new(
        doc_type: "73",
        received_at: 3.days.ago,
        document_id: "1",
        filename: "My_NOD"
      )
    )
  end

  def self.soc_document
    Document.from_vbms_document(
      OpenStruct.new(
        doc_type: "95",
        received_at: Date.new(1987, 9, 6),
        document_id: "2",
        filename: "My_SOC"
      )
    )
  end

  def self.form9_document
    Document.from_vbms_document(
      OpenStruct.new(
        doc_type: "179",
        received_at: 1.day.ago,
        document_id: "3",
        filename: "My_Form_9"
      )
    )
  end

  def self.decision_document
    Document.from_vbms_document(
      OpenStruct.new(
        doc_type: "27",
        received_at: 7.days.ago,
        document_id: "4",
        filename: "My_Decision"
      )
    )
  end

  def self.decision_document2
    Document.from_vbms_document(
      OpenStruct.new(
        doc_type: "27",
        received_at: 8.days.ago,
        document_id: "5",
        filename: "My_Decision2"
      )
    )
  end

  def self.set_vbms_documents!
    @documents = [nod_document, soc_document, form9_document, decision_document]
  end

  def self.seed!
    unless Rails.env.test?

      self.records = {
        "123C" => Fakes::AppealRepository.appeal_ready_to_certify,
        "456C" => Fakes::AppealRepository.appeal_mismatched_docs,
        "789C" => Fakes::AppealRepository.appeal_already_certified,
        "321C" => Fakes::AppealRepository.appeal_remand_decided,
        "654C" => Fakes::AppealRepository.appeal_full_grant_decided,
        "000ERR" => Fakes::AppealRepository.appeal_raises_vbms_error,
        "001ERR" => Fakes::AppealRepository.appeal_missing_data
      }
      documents = [
        nod_document,
        soc_document,
        form9_document,
        decision_document
      ]
      documents_multiple_decisions = documents.dup.push(decision_document2)

      50.times.each do |i|
        @records["vacols_id#{i}"] = appeals_for_tasks(i)
        # Make every other case have two decision documents
        @records["vbms_id#{i}"] =
          if i.even?
            {
              documents: documents,
              vbms_id: "vbms_id#{i}"
            }
          else
            {
              documents: documents_multiple_decisions,
              vbms_id: "vbms_id#{i}"
            }
          end
      end

      @records["FULLGRANT_VBMS_ID"] = {
        documents: documents_multiple_decisions,
        vbms_id: "FULLGRANT_VBMS_ID"
      }
    end
  end
end
