class Fakes::AppealRepository
  class << self
    attr_writer :records
    attr_accessor :certified_appeal
  end

  def self.certify(appeal)
    @certified_appeal = appeal
  end

  def self.find(id)
    @records[id]
  end

  def self.appeal_ready_to_certify
    Appeal.new(
      type: "Original",
      file_type: "VBMS",
      vbms_id: "VBMS-ID",
      representative: "Military Order of the Purple Heart",
      nod_date: 3.days.ago,
      soc_date: Date.new(1987, 9, 6),
      form9_date: 1.day.ago,
      documents: [nod_document, soc_document, form9_document],
      veteran_first_name: "Davy",
      veteran_last_name: "Crockett",
      appellant_name: "Susie Crockett",
      appellant_relationship: "Daughter",
      regional_office_key: "DSUSER"
    )
  end

  def self.appeal_not_ready
    Appeal.new(
      type: "Original",
      file_type: "VBMS",
      representative: "Military Order of the Purple Heart",
      nod_date: 1.day.ago,
      soc_date: Date.new(1987, 9, 6),
      form9_date: 1.day.ago,
      ssoc_dates: [6.days.from_now, 7.days.from_now],
      documents: [nod_document, soc_document],
      veteran_first_name: "Davy",
      veteran_last_name: "Crockett",
      appellant_name: "Susie Crockett",
      appellant_relationship: "Daughter",
      regional_office_key: "DSUSER"
    )
  end

  def self.appeal_already_certified
    Appeal.new(
      type: :original,
      file_type: :vbms,
      vbms_id: "VBMS-ID",
      vso_name: "Military Order of the Purple Heart",
      nod_date: 3.days.ago,
      soc_date: Date.new(1987, 9, 6),
      certification_date: 1.day.ago,
      form9_date: 1.day.ago,
      documents: [nod_document, soc_document, form9_document],
      veteran_name: "Davy Crockett",
      appellant_name: "Susie Crockett",
      appellant_relationship: "Daughter"
    )
  end

  def self.nod_document
    Document.new(type: :nod, received_at: 3.days.ago)
  end

  def self.soc_document
    Document.new(type: :soc, received_at: Date.new(1987, 9, 6))
  end

  def self.form9_document
    Document.new(type: :form9, received_at: 1.day.ago)
  end

  def self.seed!
    unless Rails.env.test?
      self.records = {
        "123C" => Fakes::AppealRepository.appeal_ready_to_certify,
        "456C" => Fakes::AppealRepository.appeal_not_ready,
        "789C" => Fakes::AppealRepository.appeal_already_certified
      }
    end
  end
end
