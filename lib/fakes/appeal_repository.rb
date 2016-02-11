class Fakes::AppealRepository
  class << self
    attr_writer :records
  end

  def self.find(id)
    @records[id]
  end

  def self.appeal_ready_to_certify
    Appeal.new(
      nod_date: 3.days.ago,
      soc_date: Date.new(1987, 9, 6),
      form9_date: 1.day.ago,
      documents: [nod_document, soc_document, form9_document]
    )
  end

  def self.appeal_not_ready
    Appeal.new(
      nod_date: 1.day.ago,
      soc_date: Date.new(1987, 9, 6),
      form9_date: 1.day.ago,
      ssoc_dates: [6.days.from_now, 7.days.from_now],
      documents: [nod_document, soc_document]
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
        "456C" => Fakes::AppealRepository.appeal_not_ready
      }
    end
  end
end
