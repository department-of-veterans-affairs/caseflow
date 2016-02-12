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

  def nod_match?
    documents_with_type(:nod).any? { |doc| doc.received_at.to_date == nod_date.to_date }
  end

  def soc_match?
    documents_with_type(:soc).any? { |doc| doc.received_at.to_date == soc_date.to_date }
  end

  def form9_match?
    documents_with_type(:form9).any? { |doc| doc.received_at.to_date == form9_date.to_date }
  end

  def ssoc_all_match?
    ssoc_dates.all? { |date| ssoc_match?(date) }
  end

  def ssoc_match?(date)
    ssoc_documents = documents_with_type(:ssoc)
    ssoc_documents.any? { |doc| doc.received_at.to_date == date.to_date }
  end

  def ready_to_certify?
    nod_match? && soc_match? && form9_match? && ssoc_all_match?
  end

  class << self
    attr_writer :repository

    def find(vacols_id)
      unless (appeal = @repository.find(vacols_id))
        fail ActiveRecord::RecordNotFound
      end

      appeal
    end

    def repository
      @repository ||= AppealRepository
    end
  end

  def documents_with_type(type)
    @documents_by_type ||= {}
    @documents_by_type[type] ||= documents.select { |doc| doc.type == type }
  end
end

class AppealRepository
  def self.find(_vacols_id, _args = {})
  end
end
