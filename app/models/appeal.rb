class Appeal
  include ActiveModel::Model

  attr_accessor :vacols_id, :vbms_id
  attr_accessor :veteran_first_name, :veteran_middle_initial, :veteran_last_name
  attr_accessor :appellant_name, :appellant_relationship, :vso_name
  attr_accessor :insurance_loan_number
  attr_accessor :certification_date
  attr_accessor :nod_date, :soc_date, :form9_date
  attr_accessor :type

  def veteran_name
    [veteran_last_name, veteran_first_name, veteran_middle_initial].select(&:present?).join(", ")
  end

  attr_writer :ssoc_dates
  def ssoc_dates
    @ssoc_dates ||= []
  end

  attr_writer :documents
  def documents
    @documents ||= []
  end

  attr_accessor :file_type
  def file_type_name
    FILE_TYPE_NAMES[file_type]
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

  def certified?
    certification_date != nil
  end

  def ssoc_match?(date)
    ssoc_documents = documents_with_type(:ssoc)
    ssoc_documents.any? { |doc| doc.received_at.to_date == date.to_date }
  end

  def documents_match?
    nod_match? && soc_match? && form9_match? && ssoc_all_match?
  end

  def certify!
    Appeal.certify(self)
  end

  class << self
    attr_writer :repository
    delegate :certify, to: :repository

    def find(vacols_id)
      unless (appeal = repository.find(vacols_id))
        fail ActiveRecord::RecordNotFound
      end

      appeal.vacols_id = vacols_id
      appeal
    end

    def repository
      @repository ||= AppealRepository
    end

    def from_records(case_record:, folder_record:, correspondent_record:)
      new(
        vbms_id: case_record.bfcorlid,
        type: Records::Case::TYPES[case_record.bfac],
        file_type: folder_record.file_type,
        vso_name: Records::Case::VSOS[case_record.bfso][:full_name],
        veteran_first_name: correspondent_record.snamef,
        veteran_middle_initial: correspondent_record.snamemi,
        veteran_last_name: correspondent_record.snamel,
        nod_date: case_record.bfdnod,
        soc_date: case_record.bfdsoc,
        form9_date: case_record.bfd19
      )
    end
  end

  def documents_with_type(type)
    @documents_by_type ||= {}
    @documents_by_type[type] ||= documents.select { |doc| doc.type == type }
  end
end
