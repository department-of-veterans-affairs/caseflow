class Appeal < ActiveRecord::Base
  include AssociatedVacolsModel

  has_many :tasks

  class MultipleDecisionError < StandardError; end

  # When these instance variable getters are called, first check if we've
  # fetched the values from VACOLS. If not, first fetch all values and save them
  # This allows us to easily call `appeal.veteran_first_name` and dynamically
  # fetch the data from VACOLS if it does not already exist in memory
  vacols_attr_accessor :veteran_first_name, :veteran_middle_initial, :veteran_last_name
  vacols_attr_accessor :appellant_first_name, :appellant_middle_initial, :appellant_last_name
  vacols_attr_accessor :appellant_name, :appellant_relationship
  vacols_attr_accessor :representative
  vacols_attr_accessor :hearing_type
  vacols_attr_accessor :hearing_requested, :hearing_held
  vacols_attr_accessor :regional_office_key
  vacols_attr_accessor :insurance_loan_number
  vacols_attr_accessor :certification_date
  vacols_attr_accessor :notification_date, :nod_date, :soc_date, :form9_date
  vacols_attr_accessor :type
  vacols_attr_accessor :disposition, :decision_date, :status
  vacols_attr_accessor :file_type
  vacols_attr_accessor :case_record

  attr_writer :ssoc_dates
  def ssoc_dates
    @ssoc_dates ||= []
  end

  attr_writer :documents
  def documents
    @documents || fetch_documents!
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

  def task_header
    "#{veteran_name} (#{vbms_id})"
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

  # TODO: (mdbenjam): Can there be multiple decisions?
  def decision
    decisions = documents_with_type("BVA Decision").select do |decision|
      (decision.received_at - decision_date).abs <= 1.day
    end
    raise MultipleDecisionError if decisions.size > 1
    decisions.first
  end

  def certify!
    Appeal.certify(self)
  end

  def fetch_documents!
    self.class.repository.fetch_documents_for(self)
    @documents
  end

  def partial_grant?
    status == "Remand" && disposition == "Allowed"
  end

  def full_grant?
    status == "Complete"
  end

  def full_remand?
    status == "Remand" && disposition == "Remanded"
  end

  def decision_type
    return "Full Grant" if full_grant?
    return "Partial Grant" if partial_grant?
  end

  class << self
    attr_writer :repository

    def find_or_create_by_vacols_id(vacols_id)
      appeal = find_or_initialize_by(vacols_id: vacols_id)
      repository.load_vacols_data(appeal)
      appeal.save

      appeal
    end

    def repository
      @repository ||= AppealRepository
    end

    def certify(appeal)
      form8 = Form8.find_by(vacols_id: appeal.vacols_id)

      fail "No Form 8 found for appeal being certified" unless form8

      repository.certify(appeal)
      repository.upload_form8(appeal, form8)
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
