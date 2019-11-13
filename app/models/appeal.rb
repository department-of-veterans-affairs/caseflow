# frozen_string_literal: true

##
# An appeal filed by a Veteran or appellant to the Board of Veterans' Appeals for VA decisions on claims for benefits.
# This is the type of appeal created by the Veterans Appeals Improvement and Modernization Act (AMA),
# which went into effect Feb 19, 2019.

class Appeal < DecisionReview
  include BgsService
  include Taskable
  include PrintsTaskTree
  include HasTaskHistory

  has_many :appeal_views, as: :appeal
  has_many :claims_folder_searches, as: :appeal
  has_many :hearings
  has_many :available_hearing_locations, as: :appeal, class_name: "AvailableHearingLocations"

  # decision_documents is effectively a has_one until post decisional motions are supported
  has_many :decision_documents, as: :appeal
  has_many :vbms_uploaded_documents
  has_many :remand_supplemental_claims, as: :decision_review_remanded, class_name: "SupplementalClaim"

  has_one :special_issue_list
  has_many :record_synced_by_job, as: :record

  with_options on: :intake_review do
    validates :receipt_date, :docket_type, presence: { message: "blank" }
    validate :validate_receipt_date
    validates :veteran_is_not_claimant, inclusion: { in: [true, false], message: "blank" }
    validates :legacy_opt_in_approved, inclusion: { in: [true, false], message: "blank" }
    validates_associated :claimants
  end

  scope :active, lambda {
    joins(:tasks)
      .group("appeals.id")
      .having("count(case when tasks.type = ? and tasks.status not in (?) then 1 end) >= ?",
              RootTask.name, Task.closed_statuses, 1)
  }

  UUID_REGEX = /^\h{8}-\h{4}-\h{4}-\h{4}-\h{12}$/.freeze
  STATE_CODES_REQUIRING_TRANSLATION_TASK = %w[VI VQ PR PH RP PI].freeze

  def document_fetcher
    @document_fetcher ||= DocumentFetcher.new(
      appeal: self, use_efolder: true
    )
  end

  def va_dot_gov_address_validator
    @va_dot_gov_address_validator ||= VaDotGovAddressValidator.new(appeal: self)
  end

  delegate :documents, :manifest_vbms_fetched_at, :number_of_documents,
           :manifest_vva_fetched_at, to: :document_fetcher

  def self.find_appeal_by_id_or_find_or_create_legacy_appeal_by_vacols_id(id)
    if UUID_REGEX.match?(id)
      find_by_uuid!(id)
    else
      LegacyAppeal.find_or_create_by_vacols_id(id)
    end
  end

  def ui_hash
    super.merge(
      docketType: docket_type,
      isOutcoded: outcoded?,
      formType: "appeal"
    )
  end

  def type
    "Original"
  end

  # Returns the most directly responsible party for an appeal when it is at the Board,
  # mirroring Legacy Appeals' location code in VACOLS
  def assigned_to_location
    return COPY::CASE_LIST_TABLE_POST_DECISION_LABEL if root_task&.status == Constants.TASK_STATUSES.completed

    active_tasks = tasks.active.visible_in_queue_table_view
    return most_recently_assigned_to_label(active_tasks) if active_tasks.any?

    on_hold_tasks = tasks.on_hold.visible_in_queue_table_view
    return most_recently_assigned_to_label(on_hold_tasks) if on_hold_tasks.any?

    # this condition is no longer needed since we only want active or on hold tasks
    return most_recently_assigned_to_label(tasks) if tasks.any?

    fetch_status.to_s.titleize
  end

  def attorney_case_reviews
    tasks.includes(:attorney_case_reviews).flat_map(&:attorney_case_reviews)
  end

  def every_request_issue_has_decision?
    eligible_request_issues.all? { |request_issue| request_issue.decision_issues.present? }
  end

  def latest_attorney_case_review
    return @latest_attorney_case_review if defined?(@latest_attorney_case_review)

    @latest_attorney_case_review = AttorneyCaseReview
      .where(task_id: tasks.pluck(:id))
      .order(:created_at).last
  end

  def reviewing_judge_name
    task = tasks.not_cancelled.where(type: JudgeDecisionReviewTask.name).order(created_at: :desc).first
    task ? task.assigned_to.try(:full_name) : ""
  end

  def eligible_request_issues
    # It's possible that two users create issues around the same time and the sequencer gets thrown off
    # (https://stackoverflow.com/questions/5818463/rails-created-at-timestamp-order-disagrees-with-id-order)
    request_issues.active.all.sort_by(&:id)
  end

  def issues
    { decision_issues: decision_issues, request_issues: request_issues }
  end

  def docket_name
    docket_type
  end

  def decision_date
    decision_document.try(:decision_date)
  end

  def decision_document
    # NOTE: This is used for outcoding and effectuations
    #       When post decisional motions are supported, this will need to be accounted for.
    decision_documents.last
  end

  def hearing_docket?
    docket_type == Constants.AMA_DOCKETS.hearing
  end

  def evidence_submission_docket?
    docket_type == Constants.AMA_DOCKETS.evidence_submission
  end

  def direct_review_docket?
    docket_type == Constants.AMA_DOCKETS.direct_review
  end

  def active?
    tasks.open.where(type: RootTask.name).any?
  end

  def ready_for_distribution?
    # Appeals are ready for distribution when the DistributionTask is the active task, meaning there are no outstanding
    #   Evidence Window or Hearing tasks, and when there are no mail tasks that legally restrict the distribution of
    #   the case, aka blocking mail tasks
    return false unless tasks.active.where(type: DistributionTask.name).any?

    MailTask.open.where(appeal: self).find_each do |mail_task|
      return false if mail_task.blocking?
    end

    true
  end

  def ready_for_distribution_at
    tasks.select { |t| t.type == "DistributionTask" }.map(&:assigned_at).max
  end

  def veteran_name
    # For consistency with LegacyAppeal.veteran_name
    veteran&.name&.formatted(:form)
  end

  def veteran_middle_initial
    veteran&.name&.middle_initial
  end

  def veteran_is_deceased
    veteran_death_date.present?
  end

  def veteran_death_date
    veteran&.date_of_death
  end

  delegate :address_line_1,
           :address_line_2,
           :address_line_3,
           :city,
           :state,
           :zip,
           :gender,
           :date_of_birth,
           :age,
           :available_hearing_locations,
           :country, to: :veteran, prefix: true

  def veteran_if_exists
    @veteran_if_exists ||= Veteran.find_by_file_number(veteran_file_number)
  end

  def veteran_closest_regional_office
    veteran_if_exists&.closest_regional_office
  end

  def veteran_available_hearing_locations
    veteran_if_exists&.available_hearing_locations
  end

  def regional_office
    nil
  end

  def advanced_on_docket?
    claimants.any? { |claimant| claimant.advanced_on_docket?(receipt_date) }
  end

  # Prefer aod? over aod going forward, as this function returns a boolean
  alias aod? advanced_on_docket?
  alias aod advanced_on_docket?

  delegate :first_name,
           :last_name,
           :name_suffix, to: :veteran, prefix: true, allow_nil: true

  def appellant
    claimants.first
  end

  delegate :first_name,
           :last_name,
           :middle_name,
           :name_suffix,
           :address_line_1,
           :city,
           :zip,
           :state, to: :appellant, prefix: true, allow_nil: true

  def cavc
    "not implemented for AMA"
  end

  def status
    BVAAppealStatus.new(appeal: self)
  end

  def previously_selected_for_quality_review
    "not implemented for AMA"
  end

  def benefit_type
    fail "benefit_type on Appeal is set per RequestIssue"
  end

  def create_issues!(new_issues)
    new_issues.each do |issue|
      issue.benefit_type ||= issue.contested_benefit_type || issue.guess_benefit_type
      issue.veteran_participant_id = veteran.participant_id
      issue.save!
      issue.create_legacy_issue_optin if issue.legacy_issue_opted_in?
    end
    request_issues.reload
  end

  def docket_number
    return "Missing Docket Number" unless receipt_date

    "#{receipt_date.strftime('%y%m%d')}-#{id}"
  end

  # For now power_of_attorney returns the first claimant's power of attorney
  def power_of_attorney
    claimants.first&.power_of_attorney
  end
  delegate :representative_name, :representative_type, :representative_address, to: :power_of_attorney, allow_nil: true

  def power_of_attorneys
    claimants.map(&:power_of_attorney)
  end

  def representatives
    vso_participant_ids = power_of_attorneys.map(&:participant_id) - [nil]
    Representative.where(participant_id: vso_participant_ids)
  end

  def external_id
    uuid
  end

  def create_tasks_on_intake_success!
    InitialTasksFactory.new(self).create_root_and_sub_tasks!
    create_business_line_tasks!
    maybe_create_translation_task
  end

  def establish!
    attempted!

    process_legacy_issues!

    clear_error!
    processed!
  end

  def set_target_decision_date!
    if direct_review_docket?
      update!(target_decision_date: receipt_date + DirectReviewDocket::DAYS_TO_DECISION_GOAL.days)
    end
  end

  def outcoded?
    root_task && root_task.status == Constants.TASK_STATUSES.completed
  end

  def root_task
    RootTask.find_by(appeal: self)
  end

  # needed for appeal status api
  def appeal_status_id
    "A#{id}"
  end

  def linked_review_ids
    Array.wrap(appeal_status_id)
  end

  def active_status?
    # For the appeal status api, and Appeal is considered open
    # as long as there are active remand claim or effectuation
    # tracked in VBMS.
    active? || active_effectuation_ep? || active_remanded_claims?
  end

  def active_effectuation_ep?
    decision_document&.end_product_establishments&.any? { |ep| ep.status_active?(sync: false) }
  end

  def location
    if active_effectuation_ep? || active_remanded_claims?
      "aoj"
    else
      "bva"
    end
  end

  def fetch_status
    if active?
      fetch_pre_decision_status
    else
      fetch_post_decision_status
    end
  end

  def fetch_pre_decision_status
    if pending_schedule_hearing_task?
      :pending_hearing_scheduling
    elsif hearing_pending?
      :scheduled_hearing
    elsif evidence_submission_hold_pending?
      :evidentiary_period
    elsif at_vso?
      :at_vso
    elsif distributed_to_a_judge?
      :decision_in_progress
    else
      :on_docket
    end
  end

  def fetch_post_decision_status
    if remand_supplemental_claims.any?
      active_remanded_claims? ? :ama_remand : :post_bva_dta_decision
    elsif effectuation_ep? && !active_effectuation_ep?
      :bva_decision_effectuation
    elsif decision_issues.any?
      # there is a period of time where there are decision issues but no
      # decision document and the decisions issues do not have decision date yet
      # wait until the document is available before showing there is a decision
      decision_document ? :bva_decision : :decision_in_progress
    elsif withdrawn?
      :withdrawn
    else
      :other_close
    end
  end

  def fetch_details_for_status
    case fetch_status
    when :bva_decision
      {
        issues: api_issues_for_status_details_issues(decision_issues)
      }
    when :ama_remand
      {
        issues: api_issues_for_status_details_issues(decision_issues)
      }
    when :post_bva_dta_decision
      post_bva_dta_decision_status_details
    when :bva_decision_effectuation
      {
        bva_decision_date: decision_event_date,
        aoj_decision_date: decision_effectuation_event_date
      }
    when :pending_hearing_scheduling
      {
        type: "video"
      }
    when :scheduled_hearing
      api_scheduled_hearing_status_details
    when :decision_in_progress
      {
        decision_timeliness: AppealSeries::DECISION_TIMELINESS.dup
      }
    else
      {}
    end
  end

  def post_bva_dta_decision_status_details
    issue_list = remanded_sc_decision_issues
    {
      issues: api_issues_for_status_details_issues(issue_list),
      bva_decision_date: decision_event_date,
      aoj_decision_date: remand_decision_event_date
    }
  end

  def api_issues_for_status_details_issues(issue_list)
    issue_list.map do |issue|
      {
        description: issue.api_status_description,
        disposition: issue.api_status_disposition
      }
    end
  end

  def api_scheduled_hearing_status_details
    {
      type: api_scheduled_hearing_type,
      date: scheduled_hearing.scheduled_for.to_date,
      location: scheduled_hearing.try(:hearing_location).try(&:name)
    }
  end

  def scheduled_hearing
    # Appeal Status api assumes that there can be multiple hearings that have happened in the past but only
    # one that is currently scheduled. Will get this by getting the hearing whose scheduled date is in the future.
    @scheduled_hearing ||= hearings.find { |hearing| hearing.scheduled_for >= Time.zone.today }
  end

  def api_scheduled_hearing_type
    return unless scheduled_hearing

    hearing_types_for_status_details = {
      V: "video",
      C: "central_office"
    }.freeze

    hearing_types_for_status_details[scheduled_hearing.request_type.to_sym]
  end

  def remanded_sc_decision_issues
    issue_list = []
    remand_supplemental_claims.each do |sc|
      sc.decision_issues.map do |di|
        issue_list << di
      end
    end

    issue_list
  end

  def pending_schedule_hearing_task?
    tasks.open.where(type: ScheduleHearingTask.name).any?
  end

  def hearing_pending?
    scheduled_hearing.present?
  end

  def evidence_submission_hold_pending?
    tasks.open.where(type: EvidenceSubmissionWindowTask.name).any?
  end

  def at_vso?
    # This task is always open, this can be used once that task is completed
    # tasks.open.where(type: InformalHearingPresentationTask.name).any?
  end

  def distributed_to_a_judge?
    tasks.any? { |t| t.is_a?(JudgeTask) }
  end

  def alerts
    @alerts ||= ApiStatusAlerts.new(decision_review: self).all.sort_by { |alert| alert[:details][:decisionDate] }
  end

  def aoj
    return if request_issues.empty?

    return "other" unless all_request_issues_same_aoj?

    request_issues.first.api_aoj_from_benefit_type
  end

  def all_request_issues_same_aoj?
    request_issues.all? do |ri|
      ri.api_aoj_from_benefit_type == request_issues.first.api_aoj_from_benefit_type
    end
  end

  def program
    return if request_issues.empty?

    if request_issues.all? { |ri| ri.benefit_type == request_issues.first.benefit_type }
      request_issues.first.benefit_type
    else
      "multiple"
    end
  end

  def docket_hash
    return unless active_status?
    return if location == "aoj"

    {
      type: fetch_docket_type,
      month: Date.parse(receipt_date.to_s).change(day: 1),
      switchDueDate: docket_switch_deadline,
      eligibleToSwitch: eligible_to_switch_dockets?
    }
  end

  def fetch_docket_type
    api_values = {
      "direct_review" => "directReview",
      "hearing" => "hearingRequest",
      "evidence_submission" => "evidenceSubmission"
    }

    api_values[docket_name]
  end

  def docket_switch_deadline
    return unless receipt_date
    return unless request_issues.active_or_ineligible.any?
    return if request_issues.active_or_ineligible.any? { |ri| ri.decision_or_promulgation_date.nil? }

    oldest = request_issues.active_or_ineligible.min_by(&:decision_or_promulgation_date)
    deadline_from_oldest_request_issue = oldest.decision_or_promulgation_date + 365.days
    deadline_from_receipt = receipt_date + 60.days

    [deadline_from_receipt, deadline_from_oldest_request_issue].max
  end

  def eligible_to_switch_dockets?
    return false unless docket_switch_deadline

    # TODO: false if hearing already taken place, to be implemented
    # https://github.com/department-of-veterans-affairs/caseflow/issues/9205
    Time.zone.today < docket_switch_deadline
  end

  def processed_in_caseflow?
    true
  end

  def processed_in_vbms?
    false
  end

  def first_distributed_to_judge_date
    judge_tasks = tasks.select { |t| t.is_a?(JudgeTask) }
    return unless judge_tasks.any?

    judge_tasks.min_by(&:created_at).created_at.to_date
  end

  def effectuation_ep?
    decision_document&.end_product_establishments&.any?
  end

  def decision_effectuation_event_date
    return unless effectuation_ep?
    return if active_effectuation_ep?

    decision_document.end_product_establishments.first.last_synced_at.to_date
  end

  def other_close_event_date
    return if active_status?
    return if decision_issues.any?

    root_task.closed_at&.to_date
  end

  def events
    @events ||= AppealEvents.new(appeal: self).all
  end

  def active_request_issues_or_decision_issues
    decision_issues.empty? ? request_issues.active.all : fetch_all_decision_issues
  end

  def fetch_all_decision_issues
    return decision_issues unless decision_issues.remanded.any?
    # only include the remanded issues if they are still being worked on
    return decision_issues if active_remanded_claims?

    super
  end

  def cavc_due_date
    decision_event_date + 120.days if decision_event_date
  end

  def available_review_options
    return ["cavc"] if request_issues.any? { |ri| ri.benefit_type == "fiduciary" }

    %w[supplemental_claim cavc]
  end

  def cancel_active_tasks
    AppealActiveTaskCancellation.new(self).call
  end

  def address
    if appellant.address.present?
      @address ||= Address.new(
        address_line_1: appellant.address_line_1,
        address_line_2: appellant.address_line_2,
        address_line_3: appellant.address_line_3,
        city: appellant.city,
        country: appellant.country,
        state: appellant.state,
        zip: appellant.zip
      )
    end
  end

  # we always want to show ratings on intake
  def can_contest_rating_issues?
    true
  end

  def finalized_decision_issues_before_receipt_date
    return [] unless receipt_date

    DecisionIssue.includes(:decision_review).where(participant_id: veteran.participant_id)
      .select(&:finalized?)
      .select do |issue|
        issue.approx_decision_date && issue.approx_decision_date < receipt_date
      end
  end

  def create_business_line_tasks!
    issues_needing_tasks = request_issues.select(&:requires_record_request_task?)
    business_lines = issues_needing_tasks.map(&:business_line).uniq

    business_lines.each do |business_line|
      next if tasks.any? { |task| task.is_a?(VeteranRecordRequest) && task.assigned_to == business_line }

      VeteranRecordRequest.create!(
        parent: root_task,
        appeal: self,
        assigned_at: Time.zone.now,
        assigned_to: business_line
      )
    end
  end

  def stuck?
    AppealsWithNoTasksOrAllTasksOnHoldQuery.new.ama_appeal_stuck?(self)
  end

  def eligible_for_death_dismissal?(_user)
    # Death dismissal processing is only for VACOLs/Legacy appeals
    false
  end

  private

  def most_recently_assigned_to_label(tasks)
    tasks.order(:created_at).last&.assigned_to_label
  end

  def maybe_create_translation_task
    veteran_state_code = veteran&.state
    va_dot_gov_address = veteran.validate_address
    state_code = va_dot_gov_address&.dig(:state_code) || veteran_state_code
  rescue Caseflow::Error::VaDotGovAPIError
    state_code = veteran_state_code
  ensure
    distribution_task = tasks.open.find_by(type: DistributionTask.name)
    TranslationTask.create_from_parent(distribution_task) if STATE_CODES_REQUIRING_TRANSLATION_TASK.include?(state_code)
  end
end
