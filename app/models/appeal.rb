class Appeal
  include ActiveModel::Model

  attr_accessor :vacols_id, :vbms_id
  attr_accessor :veteran_first_name, :veteran_middle_initial, :veteran_last_name
  attr_accessor :appellant_first_name, :appellant_middle_initial, :appellant_last_name
  attr_accessor :appellant_name, :appellant_relationship
  attr_accessor :representative
  attr_accessor :hearing_type
  attr_accessor :hearing_requested, :hearing_held
  attr_accessor :regional_office_key
  attr_accessor :insurance_loan_number
  attr_accessor :certification_date
  attr_accessor :notification_date, :nod_date, :soc_date, :form9_date
  attr_accessor :type
  attr_accessor :merged
  attr_accessor :file_type
  attr_accessor :case_record

  attr_writer :ssoc_dates
  def ssoc_dates
    @ssoc_dates ||= []
  end

  attr_writer :documents
  def documents
    @documents ||= []
  end

  def veteran_name
    [veteran_last_name, veteran_first_name, veteran_middle_initial].select(&:present?).join(", ")
  end

  def appellant_name
    if appellant_first_name
      [appellant_first_name, appellant_middle_initial, appellant_last_name].select(&:present?).join(", ")
    end
  end

  def representative_name
    representative unless ["None", "One Time Representative", "Agent", "Attorney"].include?(representative)
  end

  def representative_type
    case representative
    when "None", "One Time Representative"
      "Other"
    when "Agent", "Attorney"
      representative
    else
      "Organization"
    end
  end

  def hearing_pending?
    hearing_requested && !hearing_held
  end

  def regional_office
    VACOLS::RegionalOffice::CITIES[regional_office_key] || {}
  end

  def regional_office_name
    "#{regional_office[:city]}, #{regional_office[:state]}"
  end

  def nod_match?
    nod_date && documents_with_type("NOD").any? { |doc| doc.received_at.to_date == nod_date.to_date }
  end

  def soc_match?
    soc_date && documents_with_type("SOC").any? { |doc| doc.received_at.to_date == soc_date.to_date }
  end

  def form9_match?
    form9_date && documents_with_type("Form 9").any? { |doc| doc.received_at.to_date == form9_date.to_date }
  end

  def ssoc_all_match?
    ssoc_dates.all? { |date| ssoc_match?(date) }
  end

  def certified?
    certification_date != nil
  end

  def ssoc_match?(date)
    ssoc_documents = documents_with_type("SSOC")
    ssoc_documents.any? { |doc| doc.received_at.to_date == date.to_date }
  end

  def documents_match?
    nod_match? && soc_match? && form9_match? && ssoc_all_match?
  end

  def missing_certification_data?
    [nod_date, soc_date, form9_date].any?(&:nil?)
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

    def ssoc_dates_from(case_record)
      [
        case_record.bfssoc1,
        case_record.bfssoc2,
        case_record.bfssoc3,
        case_record.bfssoc4,
        case_record.bfssoc5
      ].map { |datetime| normalize_vacols_date(datetime) }.reject(&:nil?)
    end

    def folder_type_from(folder_record)
      if %w(Y 1 0).include?(folder_record.tivbms)
        "VBMS"
      elsif folder_record.tisubj == "Y"
        "VVA"
      else
        "Paper"
      end
    end

    # dates in VACOLS are incorrectly recorded as UTC.
    def normalize_vacols_date(datetime)
      return nil unless datetime
      utc_datetime = datetime.in_time_zone("UTC")

      Time.zone.local(
        utc_datetime.year,
        utc_datetime.month,
        utc_datetime.day
      )
    end

    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def from_records(case_record:, folder_record:, correspondent_record:)
      new(
        vbms_id: case_record.bfcorlid,
        type: VACOLS::Case::TYPES[case_record.bfac],
        file_type: folder_type_from(folder_record),
        representative: VACOLS::Case::REPRESENTATIVES[case_record.bfso][:full_name],
        veteran_first_name: correspondent_record.snamef,
        veteran_middle_initial: correspondent_record.snamemi,
        veteran_last_name: correspondent_record.snamel,
        appellant_first_name: correspondent_record.sspare1,
        appellant_middle_initial: correspondent_record.sspare2,
        appellant_last_name: correspondent_record.sspare3,
        appellant_relationship: correspondent_record.sspare1 ? correspondent_record.susrtyp : "",
        insurance_loan_number: case_record.bfpdnum,
        notification_date: normalize_vacols_date(case_record.bfdrodec),
        nod_date: normalize_vacols_date(case_record.bfdnod),
        soc_date: normalize_vacols_date(case_record.bfdsoc),
        form9_date: normalize_vacols_date(case_record.bfd19),
        ssoc_dates: ssoc_dates_from(case_record),
        hearing_type: VACOLS::Case::HEARING_TYPES[case_record.bfha],
        hearing_requested: (case_record.bfhr == "1" || case_record.bfhr == "2"),
        hearing_held: !case_record.bfha.nil?,
        regional_office_key: case_record.bfregoff,
        certification_date: case_record.bf41stat,
        case_record: case_record,
        merged: case_record.bfdc == "M"
      )
    end
  end

  def documents_with_type(type)
    @documents_by_type ||= {}
    @documents_by_type[type] ||= documents.select { |doc| doc.type?(type) }
  end

  def clear_documents!
    @documents = []
    @documents_by_type = {}
  end

  def sanitized_vbms_id
    numeric = vbms_id.gsub(/[^0-9]/, "")

    # ensure 8 digits if "C"-type id
    if vbms_id.ends_with?("C")
      numeric.rjust(8, "0")
    else
      numeric
    end
  end
end
