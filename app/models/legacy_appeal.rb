# frozen_string_literal: true

##
# An appeal that a Veteran or appellant for VA decisions on claims for benefits, filed under the laws and policies
# guiding appeals before the Veterans Appeals Improvement and Modernization Act (AMA).
# The source of truth for legacy appeals is VACOLS, but legacy appeals may also be worked in Caseflow.
# Legacy appeals have VACOLS and BGS as dependencies.

class LegacyAppeal < CaseflowRecord
  include AppealConcern
  include AssociatedVacolsModel
  include BgsService
  include CachedAttributes
  include AddressMapper
  include Taskable
  include PrintsTaskTree
  include HasTaskHistory
  include AppealAvailableHearingLocations
  include HearingRequestTypeConcern

  belongs_to :appeal_series
  has_many :dispatch_tasks, foreign_key: :appeal_id, class_name: "Dispatch::Task"
  has_many :worksheet_issues, foreign_key: :appeal_id
  has_many :appeal_views, as: :appeal
  has_many :claims_folder_searches, as: :appeal
  has_many :tasks, as: :appeal
  has_many :decision_documents, as: :appeal
  has_many :vbms_uploaded_documents, as: :appeal
  has_one :special_issue_list, as: :appeal
  has_many :record_synced_by_job, as: :record
  has_many :available_hearing_locations, as: :appeal, class_name: "AvailableHearingLocations"
  has_many :claimants, -> { Claimant.none }
  has_one :cached_vacols_case, class_name: "CachedAppeal", foreign_key: :vacols_id, primary_key: :vacols_id
  has_one :work_mode, as: :appeal
  has_one :latest_informal_hearing_presentation_task, lambda {
    not_cancelled
      .order(closed_at: :desc, assigned_at: :desc)
      .where(type: [InformalHearingPresentationTask.name, IhpColocatedTask.name], appeal_type: LegacyAppeal.name)
  }, class_name: "Task", foreign_key: :appeal_id
  accepts_nested_attributes_for :worksheet_issues, allow_destroy: true

  class UnknownLocationError < StandardError; end

  # When these instance variable getters are called, first check if we've
  # fetched the values from VACOLS. If not, first fetch all values and save them
  # This allows us to easily call `appeal.veteran_first_name` and dynamically
  # fetch the data from VACOLS if it does not already exist in memory
  vacols_attr_accessor :veteran_first_name, :veteran_middle_initial, :veteran_last_name
  vacols_attr_accessor :veteran_name_suffix, :veteran_date_of_birth, :veteran_gender
  vacols_attr_accessor :appellant_first_name, :appellant_middle_initial
  vacols_attr_accessor :appellant_last_name, :appellant_name_suffix
  vacols_attr_accessor :outcoder_first_name, :outcoder_middle_initial, :outcoder_last_name
  vacols_attr_accessor :appellant_relationship, :appellant_ssn
  vacols_attr_accessor :hearing_request_type, :video_hearing_requested
  vacols_attr_accessor :hearing_requested, :hearing_held
  vacols_attr_accessor :regional_office_key
  vacols_attr_accessor :insurance_loan_number
  vacols_attr_accessor :notification_date, :nod_date, :soc_date, :form9_date, :ssoc_dates
  vacols_attr_accessor :certification_date, :case_review_date, :notice_of_death_date
  vacols_attr_accessor :type
  vacols_attr_accessor :disposition, :decision_date, :status
  vacols_attr_accessor :location_code
  vacols_attr_accessor :file_type
  vacols_attr_accessor :case_record
  vacols_attr_accessor :number_of_issues
  vacols_attr_accessor :outcoding_date
  vacols_attr_accessor :last_location_change_date
  vacols_attr_accessor :docket_number, :docket_date, :citation_number

  # If the case is Post-Remand, this is the date the decision was made to
  # remand the original appeal
  vacols_attr_accessor :prior_decision_date

  # These are only set when you pull in a case from the Case Assignment Repository
  attr_accessor :date_assigned, :date_received, :date_completed, :signed_date, :date_due

  # These attributes are needed for the Fakes::QueueRepository.tasks_for_user to work
  # because it is using an Appeal object
  attr_accessor :assigned_to_attorney_date, :reassigned_to_judge_date, :assigned_to_location_date, :added_by,
                :created_at, :document_id, :assigned_by, :updated_at, :attorney_id

  delegate :documents, :number_of_documents, :manifest_vbms_fetched_at, :manifest_vva_fetched_at,
           to: :document_fetcher

  delegate :address_line_1, :address_line_2, :address_line_3, :city, :state, :zip, :country, :age, :sex,
           :email_address, to: :veteran, prefix: true, allow_nil: true

  # NOTE: we cannot currently match end products to a specific appeal.
  delegate :end_products, to: :veteran, allow_nil: true
  delegate :bgs_power_of_attorney, to: :power_of_attorney, allow_nil: true

  cache_attribute :aod do
    self.class.repository.aod(vacols_id)
  end

  # To match Appeals AOD behavior
  alias aod? aod
  alias advanced_on_docket? aod

  cache_attribute :dic do
    issues.map(&:dic).include?(true)
  end

  cache_attribute :remand_return_date do
    # Note: Returns nil if the appeal is active, returns false if the appeal is
    # closed but does not have a remand return date (false is cached, nil is not).
    (self.class.repository.remand_return_date(vacols_id) || false) unless active?
  end

  # Note: If any of the names here are changed, they must also be changed in SpecialIssues.js 'specialIssue` value
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
    vocational_rehab: "Vocational Rehabilitation and Employment",
    waiver_of_overpayment: "Waiver of Overpayment"
  }.freeze
  # rubocop:enable Metrics/LineLength

  # Codes for Appeals Status API
  TYPE_CODES = {
    "Original" => "original",
    "Post Remand" => "post_remand",
    "Reconsideration" => "reconsideration",
    "Court Remand" => "post_cavc_remand",
    "Clear and Unmistakable Error" => "cue"
  }.freeze

  LOCATION_CODES = {
    remand_returned_to_bva: "96",
    bva_dispatch: "4E",
    omo_office: "20",
    caseflow: "CASEFLOW",
    quality_review: "48",
    transcription: "33",
    translation: "14",
    schedule_hearing: "57",
    sr_council_dvc: "66",
    case_storage: "81",
    service_organization: "55",
    closed: "99"
  }.freeze

  READABLE_HEARING_REQUEST_TYPES = {
    central_board: "Central", # Equivalent to :central_office
    central_office: "Central",
    central: "Central",
    travel_board: "Travel",
    video: "Video",
    virtual: "Virtual"
  }.freeze

  def document_fetcher
    @document_fetcher ||= DocumentFetcher.new(
      appeal: self, use_efolder: %w[reader queue hearings].include?(RequestStore.store[:application])
    )
  end

  def va_dot_gov_address_validator
    @va_dot_gov_address_validator ||= VaDotGovAddressValidator.new(appeal: self)
  end

  def number_of_documents_after_certification
    return 0 unless certification_date

    documents.count { |d| d.received_at && d.received_at > certification_date }
  end

  cache_attribute :cached_number_of_documents_after_certification do
    begin
      number_of_documents_after_certification
    rescue Caseflow::Error::EfolderError, VBMS::HTTPError
      nil
    end
  end

  # If we do not yet have the vbms_id saved in Caseflow's DB, then
  # we want to fetch it from VACOLS, save it to the DB, then return it
  def vbms_id
    super || begin
      check_and_load_vacols_data!
      save if persisted?
      super
    end
  end

  def events
    @events ||= AppealEvents.new(appeal: self).all
  end

  def form9_due_date
    return unless notification_date && soc_date

    [notification_date + 1.year, soc_date + 60.days].max.to_date
  end

  def soc_opt_in_due_date
    return unless soc_date || !ssoc_dates.empty?

    ([soc_date] + ssoc_dates).max.to_date + 60.days
  end

  def cavc_due_date
    return unless decided_by_bva?

    (decision_date + 120.days).to_date
  end

  def appellant_address
    appellant_address_from_bgs = bgs_address_service&.address

    # Attempt to get the address from BGS, or fall back to VACOLS. These are expected
    # to have the same hash keys.
    if appellant_is_not_veteran
      appellant_address_from_bgs || get_address_from_corres_entry(case_record.correspondent)
    else
      appellant_address_from_bgs ||
        get_address_from_veteran_record(veteran) ||
        get_address_from_corres_entry(case_record.correspondent)
    end
  end

  def appellant_address_line_1
    appellant_address&.[](:address_line_1)
  end

  def appellant_address_line_2
    appellant_address&.[](:address_line_2)
  end

  def appellant_city
    appellant_address&.[](:city)
  end

  def appellant_country
    appellant_address&.[](:country)
  end

  def appellant_state
    appellant_address&.[](:state)
  end

  def appellant_zip
    appellant_address&.[](:zip)
  end

  def appellant_is_not_veteran
    !!appellant_first_name
  end

  # This seems to be valid based on definition of the claimant method in this file
  alias veteran_is_not_claimant appellant_is_not_veteran

  def appellant_email_address
    person_for_appellant&.email_address
  end

  def person_for_appellant
    return nil if appellant_ssn.blank?

    Person.find_or_create_by_ssn(appellant_ssn)
  end

  def veteran
    @veteran ||= VeteranFinder.find_best_match(sanitized_vbms_id)
  end

  def veteran_ssn
    vbms_id.ends_with?("C") ? veteran&.ssn : sanitized_vbms_id
  end

  def congressional_interest_addresses
    case_record.mail.map(&:congressional_address)
  end

  # If VACOLS has "Allowed" for the disposition, there may still be a remanded issue.
  # For the status API, we need to mark disposition as "Remanded" if there are any remanded issues
  def disposition_remand_priority
    (disposition == "Allowed" && issues.select(&:remanded?).any?) ? "Remanded" : disposition
  end

  delegate :representative_name,
           :representative_type,
           :representative_address,
           :representatives,
           :representative_to_hash,
           :representative_participant_id,
           :vacols_representatives,
           :representative_is_agent?,
           :representative_is_organization?,
           :representative_is_vso?,
           :representative_is_colocated_vso?,
           :fetch_bgs_record,
           to: :legacy_appeal_representative

  def representative_email_address
    power_of_attorney.bgs_representative_email_address
  end

  def poa_last_synced_at
    power_of_attorney.bgs_poa_last_synced_at
  end

  def legacy_appeal_representative
    @legacy_appeal_representative ||= LegacyAppealRepresentative.new(
      power_of_attorney: power_of_attorney,
      case_record: case_record
    )
  end

  def power_of_attorney
    # TODO: this will only return a single power of attorney. There are sometimes multiple values, eg.
    # when a contesting claimant is present. Refactor so we surface all POA data.
    @power_of_attorney ||= new_power_of_attorney.tap do |poa|
      # Set the VACOLS properties of the PowerOfAttorney object here explicitly so we only query the database once.
      poa.class.repository.set_vacols_values(
        poa: poa,
        case_record: case_record,
        representative: VACOLS::Representative.appellant_representative(vacols_id)
      )
    end
  end

  ## BEGIN Hearing specific attributes and methods

  attr_writer :hearings
  def hearings
    @hearings ||= HearingRepository.hearings_for_appeal(vacols_id)
  end

  def hearing_pending?
    hearing_requested && !hearing_held
  end

  def hearing_scheduled?
    scheduled_hearings.any?
  end

  def any_held_hearings?
    hearings.any?(&:held?)
  end

  def completed_hearing_on_previous_appeal?
    vacols_ids = VACOLS::Case.where(bfcorlid: vbms_id).pluck(:bfkey)
    hearings = HearingRepository.hearings_for_appeals(vacols_ids)
    hearings_on_other_appeals = hearings.reject { |hearing_appeal_id, _| hearing_appeal_id.eql?(vacols_id) }

    hearings_on_other_appeals.map do |hearing_appeal_id, case_hearings|
      if case_hearings.any?(&:held?)
        hearing_appeal_id
      end
    end.present?
  end

  def scheduled_hearings
    hearings.select(&:scheduled_pending?)
  end

  ## END Hearing specific attributes and methods

  attr_writer :cavc_decisions
  def cavc_decisions
    @cavc_decisions ||= CAVCDecision.repository.cavc_decisions_by_appeal(vacols_id)
  end

  # When the decision is signed by an attorney at BVA, an outcoder physically stamps the date,
  # checks for data accuracy and uploads the decision to VBMS
  def outcoded_by_name
    [outcoder_last_name, outcoder_first_name, outcoder_middle_initial].select(&:present?).join(", ").titleize
  end

  def contested_claim
    vacols_representatives.any? { |r| r.reptype == "C" }
  end

  def claimant
    if appellant_is_not_veteran
      {
        first_name: appellant_first_name,
        middle_name: appellant_middle_initial,
        last_name: appellant_last_name,
        name_suffix: appellant_name_suffix,
        address: appellant_address,
        representative: representative_to_hash
      }
    else
      {
        first_name: veteran_first_name,
        middle_name: veteran_middle_initial,
        last_name: veteran_last_name,
        name_suffix: veteran_name_suffix,
        address: appellant_address,
        representative: representative_to_hash
      }
    end
  end

  alias appellant claimant

  # reptype C is a contested claimant
  def contested_claimants
    vacols_representatives.where(reptype: "C").map(&:as_claimant)
  end

  # reptype D is contested claimant attorney, reptype E is contested claimant agent
  def contested_claimant_agents
    vacols_representatives.where(reptype: %w[D E]).map(&:as_claimant)
  end

  def docket_name
    "legacy"
  end

  def root_task
    RootTask.find_by(appeal: self)
  end

  # TODO: delegate this to veteran
  def can_be_accessed_by_current_user?
    bgs.can_access?(veteran_file_number)
  end

  def task_header
    "&nbsp &#124; &nbsp ".html_safe + "#{veteran_name} (#{sanitized_vbms_id})"
  end

  def eligible_for_ramp?
    !ramp_ineligibility_reason
  end

  def ramp_ineligibility_reason
    return @ramp_ineligibility_reason if defined? @ramp_ineligibility_reason

    @ramp_ineligibility_reason = begin
      if !status_eligible_for_ramp?
        :activated_to_bva
      elsif appellant_first_name
        :claimant_not_veteran
      elsif !compensation?
        :no_compensation_issues
      end
    end
  end

  def compensation_issues
    issues.select { |issue| issue.program == :compensation }
  end

  def compensation?
    !compensation_issues.empty?
  end

  def fully_compensation?
    compensation_issues.count == issues.count
  end

  def prior_bva_decision_date
    (type == "Post Remand") ? prior_decision_date : decision_date
  end

  def ramp_election
    RampElection.find_by(veteran_file_number: veteran_file_number)
  end

  def in_location?(location)
    fail UnknownLocationError unless LOCATION_CODES[location]

    location_code == LOCATION_CODES[location]
  end

  cache_attribute :case_assignment_exists do
    self.class.repository.case_assignment_exists?(vacols_id)
  end

  def attributes_for_hearing
    {
      "id" => id,
      "vbms_id" => vbms_id,
      "nod_date" => nod_date,
      "soc_date" => soc_date,
      "certification_date" => certification_date,
      "prior_bva_decision_date" => prior_bva_decision_date,
      "form9_date" => form9_date,
      "ssoc_dates" => ssoc_dates,
      "docket_number" => docket_number,
      "contested_claim" => contested_claim,
      "dic" => dic,
      "cached_number_of_documents_after_certification" => cached_number_of_documents_after_certification,
      "worksheet_issues" => worksheet_issues
    }
  end

  def nod
    @nod ||= matched_document("NOD", nod_date)
  end

  def soc
    @soc ||= fuzzy_matched_document("SOC", soc_date)
  end

  def form9
    @form9 ||= matched_document("Form 9", form9_date)
  end

  def ssocs
    # an appeal might have multiple SSOC documents so match vacols date
    # to each VBMS document
    @ssocs ||= ssoc_dates.sort.inject([]) do |docs, ssoc_date|
      docs << fuzzy_matched_document("SSOC", ssoc_date, excluding: docs)
    end
  end

  def certified?
    certification_date != nil
  end

  def documents_match?
    return false if missing_certification_data?

    nod.matching? && soc.matching? && form9.matching? && ssocs.all?(&:matching?)
  end

  def missing_certification_data?
    [nod_date, soc_date, form9_date].any?(&:nil?)
  end

  def decisions
    return [] unless decision_date

    decisions = documents_with_type(*Document::DECISION_TYPES).select do |decision|
      (decision.received_at.in_time_zone - decision_date).abs <= 3.days
    end
    decisions
  end

  # This represents the *date* that the decision occurred,
  # *NOT* a datetime. So if a decision was made in Manila,
  # it will be the date from Manila's perspective
  def serialized_decision_date
    decision_date ? decision_date.to_formatted_s(:json_date) : ""
  end

  def certify!
    LegacyAppeal.certify(self)
  end

  # These three methods are used to decide whether the appeal is processed
  # as a partial grant, remand, or full grant when dispatching it.
  def partial_grant_on_dispatch?
    status == "Remand" && issues.any?(&:non_new_material_allowed?)
  end

  def full_grant_on_dispatch?
    status == "Complete" && issues.any?(&:non_new_material_allowed?)
  end

  def remand_on_dispatch?
    remand? && issues.none?(&:non_new_material_allowed?)
  end

  def dispatch_decision_type
    return "Full Grant" if full_grant_on_dispatch?
    return "Partial Grant" if partial_grant_on_dispatch?
    return "Remand" if remand_on_dispatch?
  end

  def activated?
    # An appeal is currently at the board, and it has passed some data checks
    %w[Active Motion].include?(status)
  end

  def active?
    # All issues on an appeal have not yet been granted or denied
    status != "Complete"
  end

  def remand?
    status == "Remand"
  end

  def advance?
    status == "Advance"
  end

  def decided_by_bva?
    !active? && LegacyAppeal.bva_dispositions.include?(disposition)
  end

  def merged?
    disposition == "Merged Appeal"
  end

  def advance_failure_to_respond?
    disposition == "Advance Failure to Respond"
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

  def documents_with_type(*types)
    @documents_by_type ||= {}
    types.reduce([]) do |accumulator, type|
      @documents_by_type[type] ||= documents.select { |doc| doc.type?(type) }
      accumulator.concat(@documents_by_type[type])
    end
  end

  def clear_documents!
    @documents = []
    @documents_by_type = {}
  end

  def attorney_case_reviews
    (das_assignments || []).reject { |t| t.document_id.nil? }
  end

  def das_assignments
    @das_assignments ||= VACOLS::CaseAssignment.tasks_for_appeal(vacols_id)
  end

  def reviewing_judge_name
    das_assignments.max_by(&:created_at).try(:assigned_by_name)
  end

  attr_writer :issues
  def issues
    @issues ||= self.class.repository.issues(vacols_id)
  end

  # a list of issues with undecided dispositions (see queue/utils.getUndecidedIssues)
  def undecided_issues
    issues.select do |issue|
      issue.disposition_id.nil? ||
        Constants::UNDECIDED_VACOLS_DISPOSITIONS_BY_ID.key?(issue.disposition_id)
    end
  end

  # A uniqued list of issue categories on appeal, that is the combination of ISSPROG and ISSCODE
  def issue_categories
    issues.map(&:category).uniq
  end

  # If we do not yet have the worksheet issues saved in Caseflow's DB, then
  # we want to fetch it from VACOLS, save it to the DB, then return it
  def worksheet_issues
    unless issues_pulled
      transaction do
        issues.each { |i| WorksheetIssue.create_from_issue(self, i) }
        update!(issues_pulled: true)
      end
    end
    super
  end

  def previously_selected_for_quality_review
    !case_record.decision_quality_reviews.empty?
  end

  def outstanding_vacols_mail
    case_record.mail.map do |row|
      {
        outstanding: row.outstanding?,
        code: row.mltype,
        description: VACOLS::Mail::TYPES[row.mltype]
      }
    end
  end

  # VACOLS stores the VBA veteran unique identifier a little
  # differently from BGS and VBMS. vbms_id correlates to the
  # VACOLS formatted veteran identifier, sanitized_vbms_id
  # correlates to the VBMS/BGS veteran identifier, which is
  # sometimes called file_number.
  #
  # sanitized_vbms_id converts the vbms_id stored in VACOLS to
  # the format used by VBMS and BGS.
  #
  # TODO: clean up the terminology surrounding here.
  def sanitized_vbms_id
    # If testing against a local eFolder express instance then we want to pass DEMO
    # values, so we should not sanitize the vbms_id.
    return vbms_id.to_s if vbms_id =~ /DEMO/ && Rails.env.development?

    LegacyAppeal.veteran_file_number_from_bfcorlid vbms_id
  end

  # The sanitized_vbms_id may be a SSN value, which may or may not be a
  # valid file number as recognized by VBMS.
  # Prefer what we have in the Veteran record since that originates from VBMS
  # and therefore should be valid for external use.
  def veteran_file_number
    vacols_file_number = sanitized_vbms_id

    return vacols_file_number unless veteran

    caseflow_file_number = veteran.file_number
    if vacols_file_number != caseflow_file_number
      DataDogService.increment_counter(
        metric_group: "database_disagreement",
        metric_name: "file_number",
        app_name: RequestStore[:application],
        attrs: {
          appeal_id: external_id
        }
      )
    end
    caseflow_file_number
  end

  def pending_eps
    end_products&.select(&:dispatch_conflict?)
  end

  def non_canceled_end_products_within_30_days
    end_products&.select { |ep| ep.potential_match?(self) }
  end

  def api_supported?
    %w[original post_remand cavc_remand].include? type_code
  end

  def type_code
    TYPE_CODES[type] || "other"
  end

  def cavc
    type == "Court Remand"
  end

  def original?
    type_code == "original"
  end

  alias cavc? cavc

  # Adding anything to this to_hash can trigger a lazy load which slows down
  # welcome gate dramatically. Don't add anything to it without also adding it to
  # the query in VACOLS::CaseAssignment.
  def to_hash(viewed: nil, issues: nil, hearings: nil)
    serializable_hash(
      methods: [:veteran_full_name, :veteran_first_name, :veteran_last_name, :docket_number, :type, :cavc, :aod],
      includes: [:vbms_id, :vacols_id]
    ).tap do |hash|
      hash["viewed"] = viewed
      hash["issues"] = issues ? issues.map(&:attributes) : nil
      hash["regional_office"] = regional_office_hash
      hash["hearings"] = hearings
    end
  end

  def matchable_to_request_issue?(receipt_date)
    return false unless issues.any?
    return true if active?

    covid_flag = FeatureToggle.enabled?(:covid_timeliness_exemption, user: RequestStore.store[:current_user])

    eligible_for_opt_in?(receipt_date: receipt_date, covid_flag: covid_flag)
  end

  def eligible_for_opt_in?(receipt_date:, covid_flag: false)
    return false unless receipt_date
    return false unless soc_date

    soc_eligible_for_opt_in?(receipt_date: receipt_date, covid_flag: covid_flag) ||
      nod_eligible_for_opt_in?(receipt_date: receipt_date, covid_flag: covid_flag)
  end

  def serializer_class
    ::WorkQueue::LegacyAppealSerializer
  end

  def external_id
    vacols_id
  end

  def assigned_to_location
    return location_code unless location_code_is_caseflow?

    recently_updated_task = Task.any_recently_updated(
      tasks.active.visible_in_queue_table_view,
      tasks.on_hold.visible_in_queue_table_view
    )
    return recently_updated_task.assigned_to_label if recently_updated_task

    # shouldn't happen because if all tasks are closed the task returns to the assigning attorney
    if tasks.any?
      Raven.capture_message("legacy appeal #{external_id} has been worked in caseflow but has only closed tasks")
      return tasks.most_recently_updated.assigned_to_label
    end

    # shouldn't happen because setting location to "CASEFLOW" only happens when a task is created
    Raven.capture_message("legacy appeal #{external_id} has been worked in caseflow but is open and has no tasks")
    location_code
  end

  # Appellant's addressed wrapped as an instance of `Address`.
  def address
    @address ||= Address.new(appellant[:address]) if appellant[:address].present?
  end

  def paper_case?
    file_type.eql? "Paper"
  end

  def attorney_case_review
    # Created at date will be nil if there is no decass record created for this appeal yet
    return unless vacols_case_review&.created_at

    task_id = "#{vacols_id}-#{VacolsHelper.day_only_str(vacols_case_review.created_at)}"

    @attorney_case_review ||= AttorneyCaseReview.find_by(task_id: task_id)
  end

  def vacols_case_review
    @vacols_case_review ||= VACOLS::CaseAssignment.latest_task_for_appeal(vacols_id)
  end

  def death_dismissal!
    multi_transaction do
      cancel_open_caseflow_tasks!
      LegacyAppeal.repository.update_location_for_death_dismissal!(appeal: self)
    end
  end

  def cancel_open_caseflow_tasks!
    tasks.open.each do |task|
      task.update_with_instructions(
        status: Constants.TASK_STATUSES.cancelled,
        instructions: "Task cancelled due to death dismissal"
      )
    end
  end

  def eligible_for_death_dismissal?(user)
    return false if notice_of_death_date.nil?

    user_has_relevent_open_tasks = tasks.open.where(type: ColocatedTask.subclasses.map(&:name)).any?
    user_has_relevent_open_tasks && Colocated.singleton.user_is_admin?(user)
  end

  def location_history
    VACOLS::Priorloc.where(lockey: vacols_id).order(:locdout)
  end

  # Only AMA Appeals go to BVA Dispatch in Caseflow
  def ready_for_bva_dispatch?
    false
  end

  # Hacky logic to determine if an acting judge should see judge actions or attorney actions on a case assigned to them
  # See https://github.com/department-of-veterans-affairs/caseflow/issues/14886  for details
  def assigned_to_acting_judge_as_judge?(acting_judge)
    # First try to determine role on the case by inspecting the attorney_case_review, if there is one present.
    if attorney_case_review.present?
      return false if attorney_case_review.attorney_id == acting_judge.id

      return true if attorney_case_review.reviewing_judge_id == acting_judge.id
    end

    # In case an attorney case review does not exist in caseflow or if this acting judge was neither the judge or
    # attorney listed in the review, check to see if a decision has already been written for the appeal. If so, assume
    # this appeal is assigned to the acting judge as a judge task as a best guess
    vacols_case_review.valid_document_id?
  end

  def claimant_participant_id
    veteran_is_not_claimant ? person_for_appellant&.participant_id : veteran&.participant_id
  end

  private

  def soc_eligible_for_opt_in?(receipt_date:, covid_flag: false)
    return false unless soc_date

    # ssoc_dates are the VACOLS bfssoc* columns - see the AppealRepository class
    all_dates = ([soc_date] + ssoc_dates).compact

    latest_soc_date = all_dates.max
    return true if covid_flag && latest_soc_date >= Constants::DATES["SOC_COVID_ELIGIBLE"].to_date
    return false if latest_soc_date < Constants::DATES["AMA_ACTIVATION"].to_date

    eligible_until = self.class.next_available_business_day(latest_soc_date + 61.days)

    eligible_until >= receipt_date
  end

  def nod_eligible_for_opt_in?(receipt_date:, covid_flag: false)
    return false unless nod_date

    nod_eligible = receipt_date - 372.days
    eligible_date = covid_flag ? [nod_eligible, Constants::DATES["NOD_COVID_ELIGIBLE"].to_date].min : nod_eligible
    earliest_eligible_date = [eligible_date, Constants::DATES["AMA_ACTIVATION"].to_date].max

    nod_date >= earliest_eligible_date
  end

  def bgs_address_service
    participant_id = if appellant_is_not_veteran
                       person_for_appellant&.participant_id
                     else
                       veteran&.participant_id
                     end

    return nil if participant_id.blank?

    @bgs_address_service ||= BgsAddressService.new(participant_id: participant_id)
  end

  def location_code_is_caseflow?
    location_code == LOCATION_CODES[:caseflow]
  end

  def matched_document(type, vacols_datetime)
    return nil unless vacols_datetime

    Document.new(type: type, vacols_date: vacols_datetime.to_date).tap do |doc|
      doc.match_vbms_document_from(documents)
    end
  end

  def fuzzy_matched_document(type, vacols_datetime, excluding: [])
    return nil unless vacols_datetime

    Document.new(type: type, vacols_date: vacols_datetime.to_date).tap do |doc|
      doc.fuzzy_match_vbms_document_from(exclude_and_sort_documents(excluding))
    end
  end

  def exclude_and_sort_documents(excluding)
    excluding_ids = excluding.map(&:vbms_document_id)
    documents.reject do |doc|
      excluding_ids.include?(doc.vbms_document_id) || doc.received_at.nil?
    end.sort_by(&:received_at)
  end

  # Used for serialization
  def regional_office_hash
    regional_office.to_h
  end

  def status_eligible_for_ramp?
    (status == "Advance" || status == "Remand") && !in_location?(:remand_returned_to_bva)
  end

  def new_power_of_attorney
    PowerOfAttorney.new(
      file_number: veteran_file_number,
      claimant_participant_id: claimant_participant_id,
      vacols_id: vacols_id
    )
  end

  class << self
    def find_or_create_by_vacols_id(vacols_id)
      appeal = find_or_initialize_by(vacols_id: vacols_id)

      fail ActiveRecord::RecordNotFound unless appeal.check_and_load_vacols_data!

      # recover if another process has saved a record for this
      # appeal since this method started
      begin
        appeal.save
      rescue ActiveRecord::RecordNotUnique
        appeal = find_by!(vacols_id: vacols_id)
      end

      appeal
    end

    # This checks for weather the eligiable soc_date falls on a satuday,
    # sunday, or holiday thus adding one/two business days on the receipt_date.
    def next_available_business_day(date)
      date += 1.day if Holidays.on(date, :federal_reserve, :observed).any?
      date += 2.days if date.saturday?
      date += 1.day if date.sunday?
      date += 1.day if inauguration_day?(date)

      date
    end

    def inauguration_day?(date)
      return unless date.is_a?(Date)

      # 2001 is a past year with an inauguration date
      # This returns true for both the inauguration date, or the observed date if it falls on a Sunday
      ((date.year - 2001) % 4 == 0) && date.month == 1 && (date.day == 20 || (date.monday? && date.day == 21))
    end

    def veteran_file_number_from_bfcorlid(bfcorlid)
      return bfcorlid unless bfcorlid.match?(/\d/)

      numeric = bfcorlid.gsub(/[^0-9]/, "")

      # ensure 8 digits if "C"-type id
      if bfcorlid.ends_with?("C")
        numeric.rjust(8, "0")
      else
        numeric
      end
    end

    def fetch_appeals_by_file_number(*file_numbers)
      if file_numbers.empty?
        fail ArgumentError, "Expected at least one file number to fetch by"
      end

      repository.appeals_by_vbms_id(
        file_numbers.map { |num| convert_file_number_to_vacols(num) }
      )
    rescue Caseflow::Error::InvalidFileNumber
      raise ActiveRecord::RecordNotFound
    end

    def vbms
      VBMSService
    end

    def repository
      AppealRepository
    end

    # Wraps the closure of appeals in a transaction
    # add additional code inside the transaction by passing a block
    def close(appeal: nil, appeals: nil, user:, closed_on:, disposition:)
      fail "Only pass either appeal or appeals" if appeal && appeals

      repository.transaction do
        (appeals || [appeal]).each do |close_appeal|
          close_single(
            appeal: close_appeal,
            user: user,
            closed_on: closed_on,
            disposition: disposition
          )
        end

        yield if block_given?
      end
    end

    def reopen(appeals:, user:, disposition:, safeguards: true, reopen_issues: true)
      repository.transaction do
        appeals.each do |reopen_appeal|
          reopen_single(
            appeal: reopen_appeal,
            user: user,
            disposition: disposition,
            safeguards: safeguards,
            reopen_issues: reopen_issues
          )
        end
      end
    end

    def opt_in_decided_appeal(appeal:, user:, closed_on:)
      repository.opt_in_decided_appeal!(
        appeal: appeal,
        user: user,
        closed_on: closed_on
      )
    end

    def certify(appeal)
      form8 = Form8.find_by(vacols_id: appeal.vacols_id)
      # `find_by_vacols_id` filters out any cancelled certifications,
      # if they exist.
      certification = Certification.find_by_vacols_id(appeal.vacols_id)

      fail "No Form 8 found for appeal being certified" unless form8
      fail "No Certification found for appeal being certified" unless certification

      repository.certify(appeal: appeal, certification: certification)
      vbms.upload_document_to_vbms(appeal, form8)
      vbms.clean_document(form8.pdf_location) unless Rails.env.development?
    end

    # This method is used for converting a file_number (also called a vbms_id)
    # to be suitable for usage to query VACOLS.
    #
    # File numbers max out at 9 digits, in which they represent social security
    # numbers. They can go as low as 3 digits.
    #
    # TODO: Move this method to AppealMapper?
    def convert_file_number_to_vacols(file_number)
      file_number = file_number.delete("^0-9")

      return "#{file_number}S" if file_number.length == 9
      return "#{file_number.gsub(/^0*/, '')}C" if file_number.length.between?(3, 9)

      fail Caseflow::Error::InvalidFileNumber
    end

    # Returns a hash of appeals with appeal_id as keys and
    # related appeals as values. These are appeals
    # fetched based on the vbms_id.
    def fetch_appeal_streams(appeals)
      appeal_vbms_ids = appeals.reduce({}) { |acc, appeal| acc.merge(appeal.vbms_id => appeal.id) }

      LegacyAppeal.where(vbms_id: appeal_vbms_ids.keys).each_with_object({}) do |appeal, acc|
        appeal_id = appeal_vbms_ids[appeal.vbms_id]
        acc[appeal_id] ||= []
        acc[appeal_id] << appeal
      end
    end

    def bva_dispositions
      VACOLS::Case::BVA_DISPOSITION_CODES.map do |code|
        Constants::VACOLS_DISPOSITIONS_BY_ID[code]
      end
    end

    def nonpriority_decisions_per_year
      repository.nonpriority_decisions_per_year
    end

    def rollback_opt_in_on_decided_appeal(appeal:, user:, original_data:)
      opt_in_disposition = Constants::VACOLS_DISPOSITIONS_BY_ID[LegacyIssueOptin::VACOLS_DISPOSITION_CODE]
      return unless appeal.disposition == opt_in_disposition

      repository.rollback_opt_in_on_decided_appeal!(
        appeal: appeal,
        user: user,
        original_data: original_data
      )
    end

    private

    def close_single(appeal:, user:, closed_on:, disposition:)
      fail "Only active appeals can be closed" unless appeal.active?

      disposition_code = Constants::VACOLS_DISPOSITIONS_BY_ID.key(disposition)
      fail "Disposition #{disposition}, does not exist" unless disposition_code

      if appeal.remand?
        repository.close_remand!(
          appeal: appeal,
          user: user,
          closed_on: closed_on,
          disposition_code: disposition_code
        )
      else
        repository.close_undecided_appeal!(
          appeal: appeal,
          user: user,
          closed_on: closed_on,
          disposition_code: disposition_code
        )
      end
    end

    def reopen_single(appeal:, user:, disposition:, safeguards:, reopen_issues: true)
      disposition_code = Constants::VACOLS_DISPOSITIONS_BY_ID.key(disposition)
      fail "Disposition #{disposition}, does not exist" unless disposition_code

      # If the appeal was decided at the board, then it was a remand which means
      # we need to clear the post-remand appeal
      if appeal.decided_by_bva?
        # Currently we don't check that there is a closed post remand appeal here
        # because it requires some additional probing into VACOLS.
        # That check is in AppealsRepository.reopen_remand!

        repository.reopen_remand!(
          appeal: appeal,
          user: user,
          disposition_code: disposition_code
        )
      else
        fail "Only closed appeals can be reopened" if appeal.active?

        repository.reopen_undecided_appeal!(
          appeal: appeal,
          user: user,
          safeguards: safeguards,
          reopen_issues: reopen_issues
        )
      end
    end
  end
end
