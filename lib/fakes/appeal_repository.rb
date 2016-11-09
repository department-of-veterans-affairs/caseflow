# frozen_string_literal: true
class Fakes::AppealRepository
  class << self
    attr_writer :documents
    attr_writer :records
    attr_accessor :certified_appeal
  end

  def self.create(vacols_id, default_attrs_method_name, overrides = {})
    default_attrs = send(default_attrs_method_name)
    attrs = default_attrs.merge(overrides) # merge in overrides

    appeal = Appeal.new(vacols_id: vacols_id)
    appeal.assign_from_vacols(attrs)
    appeal
  end

  def self.certify(appeal)
    @certified_appeal = appeal
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
    return unless appeal.documents.blank?
    appeal.documents = @documents || []
  end

  def self.remands_ready_for_claims_establishment
    [@records["321C"]]
  end

  def self.amc_full_grants(decided_after:)
    [@records["654C"]].select { |appeal| appeal.decision_date > decided_after }
  end

  # TODO(mdbenjam): refactor this to map appeals to VACOLS ids?
  def self.appeal_ready_to_certify
    {
      type: "Original",
      file_type: "VBMS",
      vbms_id: "VBMS-ID",
      representative: "Military Order of the Purple Heart",
      nod_date: 3.days.ago,
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
    Document.new(type: "NOD", received_at: 3.days.ago)
  end

  def self.soc_document
    Document.new(type: "SOC", received_at: Date.new(1987, 9, 6))
  end

  def self.form9_document
    Document.new(type: "Form 9", received_at: 1.day.ago)
  end

  def self.set_vbms_documents!
    @documents = [nod_document, soc_document, form9_document]
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
      end
    end
  end
end
