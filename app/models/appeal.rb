# rubocop:disable Metrics/ClassLength
class Appeal < ActiveRecord::Base
  include AppealConcern
  include AssociatedVacolsModel
  include CachedAttributes

  belongs_to :appeal_series
  has_many :tasks
  has_many :appeal_views
  has_many :worksheet_issues
  accepts_nested_attributes_for :worksheet_issues, allow_destroy: true

  class MultipleDecisionError < StandardError; end
  class UnknownLocationError < StandardError; end

  # When these instance variable getters are called, first check if we've
  # fetched the values from VACOLS. If not, first fetch all values and save them
  # This allows us to easily call `appeal.veteran_first_name` and dynamically
  # fetch the data from VACOLS if it does not already exist in memory
  vacols_attr_accessor :veteran_first_name, :veteran_middle_initial, :veteran_last_name
  vacols_attr_accessor :appellant_first_name, :appellant_middle_initial, :appellant_last_name
  vacols_attr_accessor :outcoder_first_name, :outcoder_middle_initial, :outcoder_last_name
  vacols_attr_accessor :appellant_relationship, :appellant_ssn
  vacols_attr_accessor :appellant_city, :appellant_state
  vacols_attr_accessor :representative
  vacols_attr_accessor :hearing_request_type, :video_hearing_requested
  vacols_attr_accessor :hearing_requested, :hearing_held
  vacols_attr_accessor :regional_office_key
  vacols_attr_accessor :insurance_loan_number
  vacols_attr_accessor :notification_date, :nod_date, :soc_date, :form9_date
  vacols_attr_accessor :certification_date, :case_review_date
  vacols_attr_accessor :type
  vacols_attr_accessor :disposition, :decision_date, :status
  vacols_attr_accessor :location_code
  vacols_attr_accessor :file_type
  vacols_attr_accessor :case_record
  vacols_attr_accessor :outcoding_date
  vacols_attr_accessor :last_location_change_date
  vacols_attr_accessor :docket_number
  vacols_attr_accessor :cavc

  # If the case is Post-Remand, this is the date the decision was made to
  # remand the original appeal
  vacols_attr_accessor :prior_decision_date

  # These are only set when you pull in a case from the Case Assignment Repository
  attr_accessor :date_assigned, :date_received, :signed_date

  cache_attribute :aod do
    self.class.repository.aod(vacols_id)
  end

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

  # TODO: the type code should be the base value, and should be
  #       converted to be human readable, not vis-versa
  TYPE_CODES = {
    "Original" => "original",
    "Post Remand" => "post_remand",
    "Reconsideration" => "reconsideration",
    "Court Remand" => "cavc_remand",
    "Clear and Unmistakable Error" => "cue"
  }.freeze

  LOCATION_CODES = {
    remand_returned_to_bva: "96"
  }.freeze

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

  def number_of_documents
    documents.size
  end

  def number_of_documents_after_certification
    return 0 unless certification_date
    documents.count { |d| d.received_at > certification_date }
  end

  cache_attribute :cached_number_of_documents_after_certification do
    number_of_documents_after_certification
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
    @events ||= AppealEvents.new(appeal: self).all.sort_by(&:date)
  end

  def api_location
    (%w(Advance Remand).include? status) ? :aoj : :bva
  end

  def api_status
    @api_status ||= fetch_api_status
  end

  def api_status_hash
    case api_status
    when :decision_in_progress
      details = { test: "Hello World" }
    else
      details = {}
    end

    { type: api_status, details: details }
  end

  def alerts
    @alerts ||= AppealAlerts.new(appeal: self).all
  end

  def form9_due_date
    return unless notification_date && soc_date
    [notification_date + 1.year, soc_date + 60.days].max.to_date
  end

  def cavc_due_date
    return unless decision_date
    (decision_date + 120.days).to_date
  end

  # TODO(jd): Refactor this to create a Veteran object but *not* call BGS
  # Eventually we'd like to reference methods on the veteran with data from VACOLS
  # and only "lazy load" data from BGS when necessary
  def veteran
    @veteran ||= Veteran.new(file_number: sanitized_vbms_id).load_bgs_record!
  end

  delegate :age, to: :veteran, prefix: true

  # If VACOLS has "Allowed" for the disposition, there may still be a remanded issue.
  # For the status API, we need to mark disposition as "Remanded" if there are any remanded issues
  def disposition_remand_priority
    disposition == "Allowed" && issues.select(&:remanded?).any? ? "Remanded" : disposition
  end

  def power_of_attorney
    @poa ||= PowerOfAttorney.new(file_number: sanitized_vbms_id, vacols_id: vacols_id).load_bgs_record!
  end

  def hearings
    @hearings ||= Hearing.repository.hearings_for_appeal(vacols_id)
  end

  def scheduled_hearings
    hearings.select(&:scheduled_pending?)
  end

  # `hearing_request_type` is a direct mapping from VACOLS and has some unused
  # values. Also, `hearing_request_type` alone can't disambiguate a video hearing
  # from a travel board hearing. This method cleans all of these issues up.
  def sanitized_hearing_request_type
    case hearing_request_type
    when :central_office
      :central_office
    when :travel_board
      video_hearing_requested ? :video : :travel_board
    end
  end

  def cavc_decisions
    @cavc_decisions ||= CAVCDecision.repository.cavc_decisions_by_appeal(vacols_id)
  end

  # When the decision is signed by an attorney at BVA, an outcoder physically stamps the date,
  # checks for data accuracy and uploads the decision to VBMS
  def outcoded_by_name
    [outcoder_last_name, outcoder_first_name, outcoder_middle_initial].select(&:present?).join(", ").titleize
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
    "&nbsp &#124; &nbsp ".html_safe + "#{veteran_name} (#{sanitized_vbms_id})"
  end

  def hearing_pending?
    hearing_requested && !hearing_held
  end

  def hearing_scheduled?
    scheduled_hearings.length > 0
  end

  def eligible_for_ramp?
    (status == "Advance" || status == "Remand") && !in_location?(:remand_returned_to_bva)
  end

  def in_location?(location)
    fail UnknownLocationError unless LOCATION_CODES[location]

    location_code == LOCATION_CODES[location]
  end

  def case_assignment_exists?
    @case_assignment_exists ||= self.class.repository.case_assignment_exists?(vacols_id)
  end

  def attributes_for_hearing
    {
      "id" => id,
      "vbms_id" => vbms_id,
      "nod_date" => nod_date,
      "soc_date" => soc_date,
      "certification_date" => certification_date,
      "prior_decision_date" => prior_decision_date,
      "form9_date" => form9_date,
      "ssoc_dates" => ssoc_dates,
      "docket_number" => docket_number,
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
    Appeal.certify(self)
  end

  def fetch_documents!(save:)
    save ? find_or_create_documents! : fetched_documents
  end

  def find_or_create_documents!
    ids = fetched_documents.map(&:vbms_document_id)
    existing_documents = Document.where(vbms_document_id: ids)
                                 .includes(:annotations, :tags).each_with_object({}) do |document, accumulator|
      accumulator[document.vbms_document_id] = document
    end

    fetched_documents.map do |document|
      if existing_documents.key?(document.vbms_document_id)
        document.merge_into(existing_documents[document.vbms_document_id])
      else
        document.save!
        document
      end
    end
  end

  def partial_grant?
    status == "Remand" && issues.any?(&:non_new_material_allowed?)
  end

  def full_grant?
    status == "Complete" && issues.any?(&:non_new_material_allowed?)
  end

  def remand?
    status == "Remand" && issues.none?(&:non_new_material_allowed?)
  end

  def active?
    status != "Complete"
  end

  def merged?
    disposition == "Merged Appeal"
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

  attr_writer :issues
  def issues
    @issues ||= self.class.repository.issues(vacols_id)
  end

  # A uniqued list of issue codes on appeal, that is the combination of ISSPROG and ISSCODE
  def issue_codes
    issues.map(&:issue_code).uniq
  end

  # If we do not yet have the worksheet issues saved in Caseflow's DB, then
  # we want to fetch it from VACOLS, save it to the DB, then return it
  def worksheet_issues
    issues.each { |i| WorksheetIssue.create_from_issue(self, i) } if super.empty?
    super
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

  def api_supported?
    %w(original post_remand cavc_remand).include? type_code
  end

  def type_code
    TYPE_CODES[type] || "other"
  end

  def latest_event_date
    events.last.try(:date)
  end

  def to_hash(viewed: nil, issues: nil)
    serializable_hash(
      methods: [:veteran_full_name, :docket_number, :type, :cavc, :aod],
      includes: [:vbms_id, :vacols_id]
    ).tap do |hash|
      hash["viewed"] = viewed
      hash["issues"] = issues
      hash["regional_office"] = regional_office_hash
    end
  end

  def manifest_vbms_fetched_at
    fetch_documents_from_service!
    @manifest_vbms_fetched_at
  end

  def manifest_vva_fetched_at
    fetch_documents_from_service!
    @manifest_vva_fetched_at
  end

  private

  def fetch_api_status
    case status
    when "Advance"
      disambiguate_api_status_advance
    when "Active"
      disambiguate_api_status_active
    when "Complete"
      disambiguate_api_status_complete
    when "Remand"
      :remand
    when "Motion"
      :motion
    when "CAVC"
      :cavc
    end
  end

  def disambiguate_api_status_advance
    if certification_date
      return :scheduled_hearing if hearing_scheduled?
      return :pending_hearing_scheduling if hearing_pending?
      return :on_docket
    end

    return :pending_certification if form9_date

    return :pending_form9 if soc_date

    :pending_soc
  end

  def disambiguate_api_status_active
    return :scheduled_hearing if hearing_scheduled?

    case location_code
    when "49"
      :stayed
    when "55"
      :at_vso
    when "19", "20"
      :opinion_request
    when "14", "16", "18", "24"
      case_assignment_exists? ? :abeyance : :on_docket
    else
      case_assignment_exists? ? :decision_in_progress : :on_docket
    end
  end

  def disambiguate_api_status_complete
    case disposition
    when "Allowed", "Denied"
      :bva_decision
    when "Advance Allowed in Field", "Benefits Granted by AOJ"
      :field_grant
    when "Withdrawn", "Advance Withdrawn by Appellant/Rep",
         "Recon Motion Withdrawn", "Withdrawn from Remand"
      :withdrawn
    when "Advance Failure to Respond", "Remand Failure to Respond"
      :ftr
    when "RAMP Opt-in"
      :ramp
    when "Dismissed, Death", "Advance Withdrawn Death of Veteran"
      :death
    when "Reconsideration by Letter"
      :reconsideration
    else
      :other_close
    end
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

  # List of all end products for the appeal's veteran.
  # NOTE: we cannot currently match end products to a specific appeal.
  def end_products
    @end_products ||= Appeal.fetch_end_products(sanitized_vbms_id)
  end

  def fetch_documents_from_service!
    return if @fetched_documents

    doc_struct = document_service.fetch_documents_for(self, RequestStore.store[:current_user])

    @fetched_documents = doc_struct[:documents]
    @manifest_vbms_fetched_at = doc_struct[:manifest_vbms_fetched_at].try(:in_time_zone)
    @manifest_vva_fetched_at = doc_struct[:manifest_vva_fetched_at].try(:in_time_zone)
  end

  def fetched_documents
    fetch_documents_from_service!
    @fetched_documents
  end

  def document_service
    @document_service ||=
      if RequestStore.store[:application] == "reader" &&
         FeatureToggle.enabled?(:efolder_docs_api, user: RequestStore.store[:current_user])
        EFolderService
      else
        VBMSService
      end
  end

  # Used for serialization
  def regional_office_hash
    regional_office.to_h
  end

  class << self
    attr_writer :repository

    def find_or_create_by_vacols_id(vacols_id)
      appeal = find_or_initialize_by(vacols_id: vacols_id)

      fail ActiveRecord::RecordNotFound unless appeal.check_and_load_vacols_data!

      appeal.save
      appeal
    end

    def fetch_end_products(vbms_id)
      bgs.get_end_products(vbms_id).map { |ep_hash| EndProduct.from_bgs_hash(ep_hash) }
    end

    def for_api(appellant_ssn:)
      fail Caseflow::Error::InvalidSSN if !appellant_ssn || appellant_ssn.length < 9

      # Some appeals that are early on in the process
      # have no events recorded. We are not showing these.
      # TODD: Research and revise strategy around appeals with no events
      repository.appeals_by_vbms_id(vbms_id_for_ssn(appellant_ssn))
                .select(&:api_supported?)
                .reject { |a| a.latest_event_date.nil? }
                .sort_by(&:latest_event_date)
                .reverse
    end

    def bgs
      BGSService.new
    end

    def fetch_appeals_by_file_number(file_number)
      repository.appeals_by_vbms_id(convert_file_number_to_vacols(file_number))

    rescue Caseflow::Error::InvalidFileNumber
      raise ActiveRecord::RecordNotFound
    end

    def vbms
      VBMSService
    end

    def repository
      @repository ||= AppealRepository
    end

    # Wraps the closure of appeals in a transaction
    # add additional code inside the transaction by passing a block
    # rubocop:disable Metrics/ParameterLists
    def close(appeal:nil, appeals:nil, user:, closed_on:, disposition:, &inside_transaction)
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

        inside_transaction.call if block_given?
      end
    end
    # rubocop:enable Metrics/ParameterLists

    def certify(appeal)
      form8 = Form8.find_by(vacols_id: appeal.vacols_id)
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

    # Because SSN is not accurate in VACOLS, we pull the file
    # number from BGS for the SSN and use that to look appeals
    # up in VACOLS
    def vbms_id_for_ssn(ssn)
      file_number = bgs.fetch_file_number_by_ssn(ssn)

      fail ActiveRecord::RecordNotFound unless file_number

      convert_file_number_to_vacols(file_number)
    end

    private

    def close_single(appeal:, user:, closed_on:, disposition:)
      fail "Only active appeals can be closed" unless appeal.active?

      disposition_code = VACOLS::Case::DISPOSITIONS.key(disposition)
      fail "Disposition #{disposition}, does not exist" unless disposition_code

      repository.close!(
        appeal: appeal,
        user: user,
        closed_on: closed_on,
        disposition_code: disposition_code
      )
    end
  end
end
# rubocop:enable Metrics/ClassLength
