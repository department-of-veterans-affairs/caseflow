# frozen_string_literal: true
class Fakes::AppealRepository
  class << self
    attr_writer :documents
    attr_writer :records
    attr_accessor :certified_appeal, :uploaded_form8, :uploaded_form8_appeal
  end

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
  end

  def self.establish_claim!(claim)
    p "Submitting claim to VBMS:", claim

    # set poa_code to RAISE_VBMS_ERROR_ID to force an error while testing
    fail(VBMSError) if claim && claim["poa_code"] == RAISE_VBMS_ERROR_ID
  end

  def self.upload_form8(appeal, form8)
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

  def self.fetch_documents_for(appeal)
    vbms_record = @records[appeal.vbms_id]
    if vbms_record
      appeal.documents = vbms_record[:documents]
      return
    end
    appeal.documents = @documents || []
  end

  def self.fetch_document_file(_document)
    path = File.join(Rails.root, "lib", "pdfs", "FakeDecisionDocument.pdf")
    IO.binread(path)
  end

  def self.remands_ready_for_claims_establishment
    [@records["321C"]]
  end

  def self.amc_full_grants(decided_after:)
    [@records["654C"]].select { |appeal| appeal.decision_date > decided_after }
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
      type: "Original",
      status: "Remand",
      disposition: "Remanded",
      decision_date: 7.days.ago,
      veteran_first_name: "Davy",
      veteran_last_name: "Crockett",
      appellant_first_name: "Susie",
      appellant_last_name: "Crockett",
      appellant_relationship: "Daughter"
    }
  end

  def self.appeal_full_grant_decided
    {
      type: "Post Remand",
      status: "Complete",
      disposition: "Allowed",
      decision_date: 7.days.ago,
      veteran_first_name: "Davy",
      veteran_last_name: "Crockett",
      appellant_first_name: "Susie",
      appellant_last_name: "Crockett",
      appellant_relationship: "Daughter"
    }
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

  RAISE_VBMS_ERROR_ID = "raise_vbms_error_id".freeze

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
    Document.new(type: "NOD", received_at: 3.days.ago, document_id: "1")
  end

  def self.soc_document
    Document.new(type: "SOC", received_at: Date.new(1987, 9, 6), document_id: "2")
  end

  def self.form9_document
    Document.new(type: "Form 9", received_at: 1.day.ago, document_id: "3")
  end

  def self.decision_document
    Document.new(type: "BVA Decision", received_at: 7.days.ago, document_id: "4")
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
      50.times.each do |i|
        @records["vacols_id#{i}"] = appeals_for_tasks(i)
        @records["vbms_id#{i}"] = { documents: [nod_document, soc_document, form9_document, decision_document] }
      end
    end
  end
end
