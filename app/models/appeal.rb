class Appeal
  include ActiveModel::Model

  attr_accessor :vacols_id, :vbms_id
  attr_accessor :veteran_first_name, :veteran_middle_initial, :veteran_last_name
  attr_accessor :appellant_first_name, :appellant_middle_name, :appellant_last_name
  attr_accessor :appellant_name, :appellant_relationship
  attr_accessor :representative
  attr_accessor :hearing_type
  attr_accessor :action_code
  attr_accessor :regional_office_key
  attr_accessor :insurance_loan_number
  attr_accessor :certification_date
  attr_accessor :notification_date, :nod_date, :soc_date, :form9_date
  attr_accessor :hearing_requested, :hearing_held
  attr_accessor :merged
  attr_accessor :type
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
      [appellant_first_name, appellant_middle_name, appellant_last_name].select(&:present?).join(", ")
    end
  end

  def representative_name
    representative unless ["None", "One Time Representative", "Agent", "Attorney"].include?(representative)
  end

  def action_name
    {"1" => "1-Original",
      "2" => "2-Supplemental",
      "3" => "3-Post-remand",
      "4" => "4-Reconsideration",
      "5" => "5-Vacate",
      "6" => "6-De novo",
      "7" => "7-Court remand",
      "8" => "8-DOR",
      "9" => "9-CUE",
      "P" => "P-Post decision development",
    }[action_code]
  end

  def hearing_pending
    return hearing_requested && !hearing_held
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

  def regional_office
    Records::RegionalOffice::CITIES[regional_office_key] || {}
  end

  def regional_office_name
    "#{regional_office[:city]}, #{regional_office[:state]}"
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

  def any_appeals_document?
      [:nod, :form9, :soc, :ssoc].any? { |t| documents_with_type(t).length != 0 }
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
        type: Records::Case::TYPES[case_record.bfac],
        file_type: folder_type_from(folder_record),
        representative: Records::Case::REPRESENTATIVES[case_record.bfso][:full_name],
        veteran_first_name: correspondent_record.snamef,
        veteran_middle_initial: correspondent_record.snamemi,
        veteran_last_name: correspondent_record.snamel,
        appellant_first_name: correspondent_record.sspare1,
        appellant_middle_name: correspondent_record.sspare2,
        appellant_last_name: correspondent_record.sspare3,
        appellant_relationship: correspondent_record.sspare1 ? correspondent_record.susrtyp : "",
        insurance_loan_number: case_record.bfpdnum,
        notification_date: normalize_vacols_date(case_record.bfdrodec),
        nod_date: normalize_vacols_date(case_record.bfdnod),
        soc_date: normalize_vacols_date(case_record.bfdsoc),
        form9_date: normalize_vacols_date(case_record.bfd19),
        ssoc_dates: ssoc_dates_from(case_record),
        hearing_type: Records::Case::HEARING_TYPES[case_record.bfha],
        regional_office_key: case_record.bfregoff,
        certification_date: case_record.bf41stat,
        action_code: case_record.bfac,
        case_record: case_record,
        # bfhr: Hearing requested ("1" -> Central Office, "2" -> Travel Board)
        hearing_requested: (case_record.bfhr == "1" || case_record.bfhr == "2"),
        # bfha: Hearing action (NULL -> No hearing happened)
        hearing_held: !case_record.bfha.nil?,
        merged: case_record.bfdc == 'M'
      )
    end
  end

  def document_dates_by_type
    results = {}

    @documents.each do |doc|
      dates = results[doc.type] || []
      dates << doc.received_at.to_date
      results[doc.type] = dates
    end

    results
  end

  def documents_with_type(type)
    @documents_by_type ||= {}
    @documents_by_type[type] ||= documents.select { |doc| doc.type == type }
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
