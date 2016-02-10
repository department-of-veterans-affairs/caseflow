class Appeal
  include ActiveModel::Model

  attr_accessor :nod_date, :soc_date, :form9_date

  attr_writer :ssoc_dates
  def ssoc_dates
    @ssoc_dates ||= []
  end

  attr_writer :documents
  def documents
    @documents ||= []
  end

  def ready_to_certify?
    nod_match? && soc_match? && form9_match? && ssoc_match?
  end

  class << self
    attr_writer :repository

    delegate :find, to: :repository

    def repository
      @repository ||= AppealRepository
    end
  end

  private

  def nod_match?
    documents_with_type(:nod).any? { |doc| doc.received_at.to_date == nod_date.to_date }
  end

  def soc_match?
    documents_with_type(:soc).any? { |doc| doc.received_at.to_date == soc_date.to_date }
  end

  def form9_match?
    documents_with_type(:form9).any? { |doc| doc.received_at.to_date == form9_date.to_date }
  end

  def ssoc_match?
    ssoc_documents = documents_with_type(:ssoc)

    ssoc_dates.all? do |date|
      ssoc_documents.any? { |doc| doc.received_at.to_date == date.to_date }
    end
  end

  def documents_with_type(type)
    documents.select { |doc| doc.type == type }
  end
end

class AppealRepository
  def self.find(_vacols_id, _args = {})
  end
end
