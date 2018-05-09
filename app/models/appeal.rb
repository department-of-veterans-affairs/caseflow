# rubocop:disable Metrics/ClassLength
class Appeal < ApplicationRecord
  include AppealConcern
  include AssociatedVacolsModel
  include CachedAttributes

  belongs_to :appeal_series
  has_many :dispatch_tasks, class_name: "Dispatch::Task"
  has_many :appeal_views
  has_many :worksheet_issues
  accepts_nested_attributes_for :worksheet_issues, allow_destroy: true

  after_save :save_to_legacy_appeals
  before_destroy :destroy_legacy_appeal

  class UnknownLocationError < StandardError; end

  # When these instance variable getters are called, first check if we've
  # fetched the values from VACOLS. If not, first fetch all values and save them
  # This allows us to easily call `appeal.veteran_first_name` and dynamically
  # fetch the data from VACOLS if it does not already exist in memory
  vacols_attr_accessor :veteran_first_name, :veteran_middle_initial, :veteran_last_name
  vacols_attr_accessor :veteran_date_of_birth, :veteran_gender
  vacols_attr_accessor :appellant_first_name, :appellant_middle_initial, :appellant_last_name
  vacols_attr_accessor :outcoder_first_name, :outcoder_middle_initial, :outcoder_last_name
  vacols_attr_accessor :appellant_relationship, :appellant_ssn
  vacols_attr_accessor :appellant_address_line_1, :appellant_address_line_2
  vacols_attr_accessor :appellant_city, :appellant_state, :appellant_country, :appellant_zip
  vacols_attr_accessor :representative, :contested_claim
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

  # If the case is Post-Remand, this is the date the decision was made to
  # remand the original appeal
  vacols_attr_accessor :prior_decision_date

  # These are only set when you pull in a case from the Case Assignment Repository
  attr_accessor :date_assigned, :date_received, :date_completed, :signed_date, :docket_date, :date_due

  # These attributes are needed for the Fakes::QueueRepository.tasks_for_user to work
  # because it is using an Appeal object
  attr_accessor :assigned_to_attorney_date, :reassigned_to_judge_date, :assigned_to_location_date, :added_by_first_name,
                :added_by_middle_name, :added_by_last_name, :added_by_css_id, :created_at, :document_id,
                :assigned_by_first_name, :assigned_by_last_name

  cache_attribute :aod do
    self.class.repository.aod(vacols_id)
  end

  cache_attribute :dic do
    issues.map(&:dic).include?(true)
  end

  cache_attribute :remand_return_date do
    # Note: Returns nil if the appeal is active, returns false if the appeal is
    # closed but does not have a remand return date (false is cached, nil is not).
    (self.class.repository.remand_return_date(vacols_id) || false) unless active?
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

  BVA_DISPOSITIONS = [
    "Allowed", "Remanded", "Denied", "Vacated", "Denied", "Vacated",
    "Dismissed, Other", "Dismissed, Death", "Withdrawn"
  ].freeze

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

  def number_of_documents_url
    if document_service == ExternalApi::EfolderService
      ExternalApi::EfolderService.efolder_files_url
    else
      "/queue/docs_for_dev"
    end
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

  def v1_events
    @v1_events ||= AppealEvents.new(appeal: self, version: 1).all.sort_by(&:date)
  end

  def events
    @events ||= AppealEvents.new(appeal: self).all
  end

  def form9_due_date
    return unless notification_date && soc_date
    [notification_date + 1.year, soc_date + 60.days].max.to_date
  end

  def cavc_due_date
    return unless decision_date
    (decision_date + 120.days).to_date
  end

  def veteran
    @veteran ||= Veteran.find_or_create_by_file_number(veteran_file_number)
  end

  delegate :age, to: :veteran, prefix: true
  delegate :sex, to: :veteran, prefix: true

  # NOTE: we cannot currently match end products to a specific appeal.
  delegate :end_products, to: :veteran

  # If VACOLS has "Allowed" for the disposition, there may still be a remanded issue.
  # For the status API, we need to mark disposition as "Remanded" if there are any remanded issues
  def disposition_remand_priority
    (disposition == "Allowed" && issues.select(&:remanded?).any?) ? "Remanded" : disposition
  end

  def power_of_attorney(load_bgs_record: true)
    @poa ||= PowerOfAttorney.new(file_number: veteran_file_number, vacols_id: vacols_id)

    load_bgs_record ? @poa.load_bgs_record! : @poa
  end

  attr_writer :hearings
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

  attr_writer :cavc_decisions
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

  # TODO: delegate this to veteran
  def can_be_accessed_by_current_user?
    self.class.bgs.can_access?(veteran_file_number)
  end

  def task_header
    "&nbsp &#124; &nbsp ".html_safe + "#{veteran_name} (#{sanitized_vbms_id})"
  end

  def hearing_pending?
    hearing_requested && !hearing_held
  end

  def hearing_scheduled?
    !scheduled_hearings.empty?
  end

  def eligible_for_ramp?
    (status == "Advance" || status == "Remand") && !in_location?(:remand_returned_to_bva)
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
    Appeal.certify(self)
  end

  def fetch_documents!(save:)
    save ? find_or_create_documents! : fetched_documents
  end

  def find_or_create_documents_v2!
    AddSeriesIdToDocumentsJob.perform_now(self)

    ids = fetched_documents.map(&:vbms_document_id)
    existing_documents = Document.where(vbms_document_id: ids)
      .includes(:annotations, :tags).each_with_object({}) do |document, accumulator|
      accumulator[document.vbms_document_id] = document
    end

    fetched_documents.map do |document|
      begin
        if existing_documents[document.vbms_document_id]
          document.merge_into(existing_documents[document.vbms_document_id]).save!
          existing_documents[document.vbms_document_id]
        else
          create_new_document!(document, ids)
        end
      rescue ActiveRecord::RecordNotUnique
        Document.find_by_vbms_document_id(document.vbms_document_id)
      end
    end
  end

  def find_or_create_documents!
    return find_or_create_documents_v2! if FeatureToggle.enabled?(:efolder_api_v2,
                                                                  user: RequestStore.store[:current_user])
    ids = fetched_documents.map(&:vbms_document_id)
    existing_documents = Document.where(vbms_document_id: ids)
      .includes(:annotations, :tags).each_with_object({}) do |document, accumulator|
      accumulator[document.vbms_document_id] = document
    end

    fetched_documents.map do |document|
      begin
        if existing_documents[document.vbms_document_id]
          document.merge_into(existing_documents[document.vbms_document_id]).save!
          existing_documents[document.vbms_document_id]
        else
          document.save!
          document
        end
      rescue ActiveRecord::RecordNotUnique
        Document.find_by_vbms_document_id(document.vbms_document_id)
      end
    end
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

  def active?
    status != "Complete"
  end

  def remand?
    status == "Remand"
  end

  def decided_by_bva?
    !active? && BVA_DISPOSITIONS.include?(disposition)
  end

  def merged?
    disposition == "Merged Appeal"
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

    numeric = vbms_id.gsub(/[^0-9]/, "")

    # ensure 8 digits if "C"-type id
    if vbms_id.ends_with?("C")
      numeric.rjust(8, "0")
    else
      numeric
    end
  end

  # Alias sanitized_vbms_id becauase file_number is the term used VBA wide for this veteran identifier
  def veteran_file_number
    sanitized_vbms_id
  end

  def pending_eps
    end_products.select(&:dispatch_conflict?)
  end

  def non_canceled_end_products_within_30_days
    end_products.select { |ep| ep.potential_match?(self) }
  end

  def api_supported?
    %w[original post_remand cavc_remand].include? type_code
  end

  def type_code
    TYPE_CODES[type] || "other"
  end

  def latest_event_date
    v1_events.last.try(:date)
  end

  def cavc
    type == "Court Remand"
  end

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

  def manifest_vbms_fetched_at
    fetch_documents_from_service!
    @manifest_vbms_fetched_at
  end

  def manifest_vva_fetched_at
    fetch_documents_from_service!
    @manifest_vva_fetched_at
  end

  private

  def save_to_legacy_appeals
    legacy_appeal = LegacyAppeal.find(attributes["id"])
    legacy_appeal.update!(attributes)
  rescue ActiveRecord::RecordNotFound
    LegacyAppeal.create!(attributes)
  end

  def destroy_legacy_appeal
    LegacyAppeal.find(attributes["id"]).destroy!
  end

  def create_new_document!(document, ids)
    document.save!

    # Find the most recent saved document with the given series_id that is not in the list of ids passed.
    previous_documents = Document.where(series_id: document.series_id).order(:id)
      .where.not(vbms_document_id: ids)

    if previous_documents.count > 0
      document.copy_metadata_from_document(previous_documents.last)
    end

    document
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
      if %w[reader queue hearings].include?(RequestStore.store[:application])
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

    def for_api(vbms_id:)
      # Some appeals that are early on in the process
      # have no events recorded. We are not showing these.
      # TODD: Research and revise strategy around appeals with no events
      repository.appeals_by_vbms_id(vbms_id)
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

    # rubocop:disable Metrics/ParameterLists
    # Wraps the closure of appeals in a transaction
    # add additional code inside the transaction by passing a block
    def close(appeal: nil, appeals: nil, user:, closed_on:, disposition:, election_receipt_date:, &inside_transaction)
      fail "Only pass either appeal or appeals" if appeal && appeals

      repository.transaction do
        (appeals || [appeal]).each do |close_appeal|
          next unless close_appeal.nod_date < election_receipt_date
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

    def reopen(appeals:, user:, disposition:)
      repository.transaction do
        appeals.each do |reopen_appeal|
          reopen_single(
            appeal: reopen_appeal,
            user: user,
            disposition: disposition
          )
        end
      end
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

    # Because SSN is not accurate in VACOLS, we pull the file
    # number from BGS for the SSN and use that to look appeals
    # up in VACOLS
    def vbms_id_for_ssn(ssn)
      file_number = bgs.fetch_file_number_by_ssn(ssn)

      fail ActiveRecord::RecordNotFound unless file_number

      convert_file_number_to_vacols(file_number)
    end

    # Returns a hash of appeals with appeal_id as keys and
    # related appeals as values. These are appeals
    # fetched based on the vbms_id.
    def fetch_appeal_streams(appeals)
      appeal_vbms_ids = appeals.reduce({}) { |acc, appeal| acc.merge(appeal.vbms_id => appeal.id) }

      Appeal.where(vbms_id: appeal_vbms_ids.keys).each_with_object({}) do |appeal, acc|
        appeal_id = appeal_vbms_ids[appeal.vbms_id]
        acc[appeal_id] ||= []
        acc[appeal_id] << appeal
      end
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

    def reopen_single(appeal:, user:, disposition:)
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
          user: user
        )
      end
    end
  end
end
# rubocop:enable Metrics/ClassLength
