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
  vacols_attr_accessor :hearing_request_type
  vacols_attr_accessor :hearing_requested, :hearing_held
  vacols_attr_accessor :regional_office_key
  vacols_attr_accessor :insurance_loan_number
  vacols_attr_accessor :certification_date
  vacols_attr_accessor :notification_date, :nod_date, :soc_date, :form9_date
  vacols_attr_accessor :type
  vacols_attr_accessor :disposition, :decision_date, :status
  vacols_attr_accessor :file_type
  vacols_attr_accessor :case_record
  vacols_attr_accessor :outcoding_date

  # Note: If any of the names here are changed, they must also be changed in SpecialIssues.js
  # rubocop:disable Metrics/LineLength
  SPECIAL_ISSUES = {
    contaminated_water_at_camp_lejeune: "Contaminated Water at Camp LeJeune",
    dic_death_or_accrued_benefits_united_states: "DIC - death, or accrued benefits - United States",
    education_gi_bill_dependents_educational_assistance_scholars: "Education - GI Bill, dependents educational assistance, scholarship, transfer of entitlement",
    foreign_claim_compensation_claims_dual_claims_appeals: "Foreign claim - compensation claims, dual claims, appeals",
    foreign_pension_dic_all_other_foreign_countries: "Foreign pension, DIC - all other foreign countries",
    foreign_pension_dic_mexico_central_and_south_america_caribb: "Foreign pension, DIC - Mexico, Central and South America, Caribbean",
    hearing_including_travel_board_video_conference: "Hearing - including travel board & video conference",
    home_loan_guaranty: "Home Loan Guaranty",
    incarcerated_veterans: "Incarcerated Veterans",
    insurance: "Insurance",
    manlincon_compliance: "Manlincon Compliance",
    mustard_gas: "Mustard Gas",
    national_cemetery_administration: "National Cemetery Administration",
    nonrating_issue: "Non-rating issue",
    pension_united_states: "Pension - United States",
    private_attorney_or_agent: "Private Attorney or Agent",
    radiation: "Radiation",
    rice_compliance: "Rice Compliance",
    spina_bifida: "Spina Bifida",
    us_territory_claim_american_samoa_guam_northern_mariana_isla: "U.S. Territory claim - American Samoa, Guam, Northern Mariana Islands (Rota, Saipan & Tinian)",
    us_territory_claim_philippines: "U.S. Territory claim - Philippines",
    us_territory_claim_puerto_rico_and_virgin_islands: "U.S. Territory claim - Puerto Rico and Virgin Islands",
    vamc: "VAMC",
    vocational_rehab: "Vocational Rehab",
    waiver_of_overpayment: "Waiver of Overpayment"
  }.freeze
  # rubocop:enable Metrics/LineLength

  attr_writer :ssoc_dates
  def ssoc_dates
    @ssoc_dates ||= []
  end

  attr_writer :documents
  def documents
    @documents ||= fetch_documents!(save: false)
  end

  # This method fetches documents and saves their metadata
  # in the database
  attr_writer :saved_documents
  def saved_documents
    @saved_documents ||= fetch_documents!(save: true)
  end

  def veteran_name
    [veteran_last_name, veteran_first_name, veteran_middle_initial].select(&:present?).join(", ")
  end

  def veteran_full_name
    [veteran_first_name, veteran_middle_initial, veteran_last_name].select(&:present?).join(" ").titleize
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

  def can_be_accessed_by_current_user?
    self.class.bgs.can_access?(sanitized_vbms_id)
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
    return [] unless decision_date

    decisions = documents_with_type("BVA Decision").select do |decision|
      (decision.received_at.in_time_zone - decision_date).abs <= 3.days
    end
    decisions
  end

  def form9
    # TODO: should be most recent form9, not first.
    documents_with_type("Form 9").first
  end

  def serialized_decision_date
    decision_date ? decision_date.to_formatted_s(:json_date) : ""
  end

  def certify!
    Appeal.certify(self)
  end

  def fetch_documents!(save:)
    save ? fetched_documents.map(&:load_or_save!) : fetched_documents
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

  def special_issues
    SPECIAL_ISSUES.inject([]) do |list, special_issue|
      send(special_issue[0]) ? (list + [special_issue[1]]) : list
    end
  end

  def special_issues?
    SPECIAL_ISSUES.keys.any? do |special_issue|
      send(special_issue)
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

  def pending_eps
    end_products.select(&:dispatch_conflict?)
  end

  def non_canceled_end_products_within_30_days
    end_products.select { |ep| ep.potential_match?(self) }
  end

  private

  # List of all end products for the appeal's veteran.
  # NOTE: we cannot currently match end products to a specific appeal.
  def end_products
    @end_products ||= Appeal.fetch_end_products(sanitized_vbms_id)
  end

  def fetched_documents
    @fetched_documents ||= self.class.repository.fetch_documents_for(self)
  end

  class << self
    attr_writer :repository

    def find_or_create_by_vacols_id(vacols_id)
      appeal = find_or_initialize_by(vacols_id: vacols_id)
      repository.load_vacols_data(appeal)
      appeal.save

      appeal
    end

    def fetch_end_products(vbms_id)
      bgs.get_end_products(vbms_id).map { |ep_hash| EndProduct.from_bgs_hash(ep_hash) }
    end

    def bgs
      BGSService.new
    end

    def repository
      @repository ||= AppealRepository
    end

    def certify(appeal)
      form8 = Form8.find_by(vacols_id: appeal.vacols_id)

      fail "No Form 8 found for appeal being certified" unless form8

      repository.certify(appeal)
      repository.upload_document_to_vbms(appeal, form8)
      repository.clean_document(form8.pdf_location)
    end
  end
end
