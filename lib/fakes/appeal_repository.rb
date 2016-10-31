# frozen_string_literal: true
class Fakes::AppealRepository
  class << self
    attr_writer :records
    attr_accessor :certified_appeal
  end

  def self.certify(appeal)
    @certified_appeal = appeal
  end

  def self.find(id)
    # timing a hash access is unnecessery but this adds coverage to MetricsService in dev mode
    record = MetricsService.timer "load appeal #{id}" do
      @records[id]
    end

    fail VBMSError if !record.nil? && RAISE_VBMS_ERROR_ID == record.vbms_id

    record
  end

  def self.appeal_mismatched_nod
    Appeal.new(
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
    )
  end

  def self.appeal_mismatched_ssoc
    Appeal.new(
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
    )
  end

  def self.appeal_mismatched_docs
    Appeal.new(
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
    )
  end

  def self.appeal_already_certified
    Appeal.new(
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
    )
  end

  def self.appeal_to_create_end_product
    Appeal.new(
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
    )
  end

  RAISE_VBMS_ERROR_ID = "raise_vbms_error_id".freeze

  def self.appeal_raises_vbms_error
    a = appeal_ready_to_certify
    a.vbms_id = RAISE_VBMS_ERROR_ID
    a
  end

  def self.appeal_missing_data
    a = appeal_ready_to_certify
    a.form9_date = nil
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

  def self.seed!
    unless Rails.env.test?
      self.records = {
        "123C" => Fakes::AppealRepository.appeal_ready_to_certify,
        "456C" => Fakes::AppealRepository.appeal_mismatched_docs,
        "789C" => Fakes::AppealRepository.appeal_already_certified,
        "000ERR" => Fakes::AppealRepository.appeal_raises_vbms_error,
        "001ERR" => Fakes::AppealRepository.appeal_missing_data
      }
    end
  end
end
