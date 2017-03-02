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

  SPECIAL_ISSUE_COLUMNS = %i(contaminated_water_at_camp_lejeune
                             dic_death_or_accrued_benefits_united_states
                             education_gi_bill_dependents_educational_assistance_scholars
                             foreign_claim_compensation_claims_dual_claims_appeals
                             foreign_pension_dic_all_other_foreign_countries
                             foreign_pension_dic_mexico_central_and_south_american_caribb
                             hearing_including_travel_board_video_conference
                             home_loan_guarantee incarcerated_veterans insurance
                             manlincon_compliance mustard_gas national_cemetery_administration
                             nonrating_issue pension_united_states private_attorney_or_agent
                             radiation rice_compliance spina_bifida
                             us_territory_claim_american_samoa_guam_northern_mariana_isla
                             us_territory_claim_philippines
                             us_territory_claim_puerto_rico_and_virgin_islands
                             vamc vocational_rehab waiver_of_overpayment).freeze

  attr_writer :ssoc_dates
  def ssoc_dates
    @ssoc_dates ||= []
  end

  attr_writer :documents
  def documents
    @documents ||= fetch_documents!(save: false)
  end

  attr_writer :saved_documents
  def saved_documents
    @saved_documents ||= fetch_documents!(save: true)
  end

  def veteran_name
    [veteran_last_name, veteran_first_name, veteran_middle_initial].select(&:present?).join(", ")
  end

  def veteran_full_name
    [veteran_first_name, veteran_middle_initial, veteran_last_name].select(&:present?).join(" ")
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
    "&nbsp &#124; &nbsp ".html_safe + "#{veteran_name} (#{vbms_id})"
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

  def station_key
    result = VACOLS::RegionalOffice::STATIONS.find { |_station, ros| [*ros].include? regional_office_key }
    result && result.first
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

  def decisions
    decisions = documents_with_type("BVA Decision").select do |decision|
      (decision.received_at.in_time_zone - decision_date).abs <= 3.days
    end
    decisions
  end

  def serialized_decision_date
    decision_date.to_formatted_s(:json_date)
  end

  def certify!
    Appeal.certify(self)
  end

  def uncertify!(user_id)
    return unless user_id == ENV["TEST_USER_ID"]
    Appeal.uncertify(self)
  end

  def fetch_documents!(save:)
    self.class.repository.fetch_documents_for(self, save: save)
    @documents
  end

  def partial_grant?
    status == "Remand" && disposition == "Allowed"
  end

  def full_grant?
    status == "Complete"
  end

  def remand?
    status == "Remand" && disposition == "Remanded"
  end

  def decision_type
    return "Full Grant" if full_grant?
    return "Partial Grant" if partial_grant?
    return "Remand" if remand?
  end

  # Does this appeal have any special issues
  def special_issues?
    SPECIAL_ISSUE_COLUMNS.any? do |special_issue|
      method(special_issue).call
    end
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
      repository.upload_and_clean_document(appeal, form8)
    end

    # ONLY FOR TEST USER and for TEST_APPEAL_ID
    def uncertify(appeal)
      Form8.delete_all(vacols_id: appeal.vacols_id)
      repository.uncertify(appeal)
    end

    def map_end_product_value(code, mapping)
      mapping[code] || code
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

  def select_non_canceled_end_products_within_30_days(end_products)
    # Find all EPs with relevant type codes that are not canceled.
    end_products.select do |end_product|
      claim_date = DateTime.strptime(end_product[:claim_receive_date], "%m/%d/%Y").in_time_zone
      (claim_date - decision_date).abs < 30.days &&
        end_product[:status_type_code] != "CAN"
    end
  end

  def select_pending_eps(end_products)
    # Find all pending EPs
    end_products.select do |end_product|
      end_product[:status_type_code] == "PEND"
    end
  end

  def bgs
    @bgs ||= BGSService.new
  end

  def pending_eps
    end_products = Dispatch.filter_dispatch_end_products(
      bgs.get_end_products(sanitized_vbms_id))

    Dispatch.map_ep_values(select_pending_eps(end_products))
  end

  def non_canceled_end_products_within_30_days
    end_products = Dispatch.filter_dispatch_end_products(
      bgs.get_end_products(sanitized_vbms_id))

    Dispatch.map_ep_values(select_non_canceled_end_products_within_30_days(end_products))
  end

  def issues
    @issues ||= self.class.repository.issues(vacols_id: vacols_id)
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
