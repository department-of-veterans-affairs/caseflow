# rubocop:disable Metrics/ClassLength
class Appeal < DecisionReview
  include Taskable
  include DocumentConcern

  has_many :appeal_views, as: :appeal
  has_many :claims_folder_searches, as: :appeal
  has_many :hearings
  has_many :available_hearing_locations, as: :appeal, class_name: "AvailableHearingLocations"

  # decision_documents is effectively a has_one until post decisional motions are supported
  has_many :decision_documents
  has_many :remand_supplemental_claims, as: :decision_review_remanded, class_name: "SupplementalClaim"

  has_one :special_issue_list

  with_options on: :intake_review do
    validates :receipt_date, :docket_type, presence: { message: "blank" }
    validates :veteran_is_not_claimant, inclusion: { in: [true, false], message: "blank" }
    validates :legacy_opt_in_approved, inclusion: { in: [true, false], message: "blank" }, if: :legacy_opt_in_enabled?
    validates_associated :claimants
  end

  scope :join_aod_motions, lambda {
    joins(claimants: :person)
      .joins("LEFT OUTER JOIN advance_on_docket_motions on advance_on_docket_motions.person_id = people.id")
  }

  scope :all_priority, lambda {
    join_aod_motions
      .where("advance_on_docket_motions.created_at > appeals.established_at")
      .where("advance_on_docket_motions.granted = ?", true)
      .or(join_aod_motions
        .where("people.date_of_birth <= ?", 75.years.ago))
    # TODO: this method returns duplicate results when appeals match both clauses in the `or`.
    # adding .distinct here throws an error when combined with other scopes using .order.
    # ensure results are distinct.
  }

  # rubocop:disable Metrics/LineLength
  scope :all_nonpriority, lambda {
    join_aod_motions
      .where("people.date_of_birth > ?", 75.years.ago)
      .group("appeals.id")
      .having("count(case when advance_on_docket_motions.granted and advance_on_docket_motions.created_at > appeals.established_at then 1 end) = ?", 0)
  }
  # rubocop:enable Metrics/LineLength

  scope :ready_for_distribution, lambda {
    joins(:tasks)
      .group("appeals.id")
      .having("count(case when tasks.type = ? and tasks.status = ? then 1 end) >= ?",
              DistributionTask.name, Constants.TASK_STATUSES.assigned, 1)
  }

  scope :non_ihp, lambda {
    joins(:tasks)
      .group("appeals.id")
      .having("count(case when tasks.type = ? then 1 end) = ?",
              InformalHearingPresentationTask.name, 0)
  }

  scope :active, lambda {
    joins(:tasks)
      .group("appeals.id")
      .having("count(case when tasks.type = ? and tasks.status not in (?) then 1 end) >= ?",
              RootTask.name, Task.inactive_statuses, 1)
  }

  scope :ordered_by_distribution_ready_date, lambda {
    joins(:tasks)
      .group("appeals.id")
      .order("max(case when tasks.type = 'DistributionTask' then tasks.assigned_at end)")
  }

  scope :priority_ordered_by_distribution_ready_date, lambda {
    from(all_priority).ordered_by_distribution_ready_date
  }

  UUID_REGEX = /^\h{8}-\h{4}-\h{4}-\h{4}-\h{12}$/.freeze
  STATE_CODES_REQUIRING_TRANSLATION_TASK = %w[VI VQ PR PH RP PI].freeze

  def document_fetcher
    @document_fetcher ||= DocumentFetcher.new(
      appeal: self, use_efolder: true
    )
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

  def self.nonpriority_decisions_per_year
    appeal_ids = all_nonpriority
      .joins(:decision_documents)
      .where("decision_date > ?", 1.year.ago)
      .select("appeals.id")
    where(id: appeal_ids).count
  end

  def ui_hash
    super.merge(
      docketType: docket_type,
      isOutcoded: outcoded?,
      formType: "appeal"
    )
  end

  def caseflow_only_edit_issues_url
    "/appeals/#{uuid}/edit"
  end

  def type
    "Original"
  end

  # Returns the most directly responsible party for an appeal when it is at the Board,
  # mirroring Legacy Appeals' location code in VACOLS
  def location_code
    return COPY::CASE_LIST_TABLE_POST_DECISION_LABEL if root_task&.status == Constants.TASK_STATUSES.completed

    active_tasks = tasks.where(status: [Constants.TASK_STATUSES.in_progress, Constants.TASK_STATUSES.assigned])
    return most_recently_assigned_to_label(active_tasks) if active_tasks.any?

    on_hold_tasks = tasks.where(status: Constants.TASK_STATUSES.on_hold)
    return most_recently_assigned_to_label(on_hold_tasks) if on_hold_tasks.any?

    return most_recently_assigned_to_label(tasks) if tasks.any?

    status_hash[:type].to_s.titleize
  end

  def attorney_case_reviews
    tasks.map(&:attorney_case_reviews).flatten
  end

  def every_request_issue_has_decision?
    eligible_request_issues.all? { |request_issue| request_issue.decision_issues.present? }
  end

  def reviewing_judge_name
    task = tasks.order(created_at: :desc).detect { |t| t.is_a?(JudgeTask) }
    task ? task.assigned_to.try(:full_name) : ""
  end

  def eligible_request_issues
    # It's possible that two users create issues around the same time and the sequencer gets thrown off
    # (https://stackoverflow.com/questions/5818463/rails-created-at-timestamp-order-disagrees-with-id-order)
    open_request_issues.select(&:eligible?).sort_by(&:id)
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
    docket_type == "hearing"
  end

  def evidence_submission_docket?
    docket_type == "evidence_submission"
  end

  def direct_review_docket?
    docket_type == "direct_review"
  end

  def active?
    tasks.active.where(type: RootTask.name).any?
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
           :closest_regional_office,
           :available_hearing_locations,
           :country, to: :veteran, prefix: true

  delegate :city,
           :state, to: :appellant, prefix: true

  def regional_office
    nil
  end

  def advanced_on_docket
    claimants.any? { |claimant| claimant.advanced_on_docket(receipt_date) }
  end

  delegate :closest_regional_office,
           :first_name,
           :last_name,
           :name_suffix,
           :ssn, to: :veteran, prefix: true, allow_nil: true

  def appellant
    claimants.first
  end

  delegate :first_name, :last_name, :middle_name, :name_suffix, to: :appellant, prefix: true, allow_nil: true

  def cavc
    "not implemented for AMA"
  end

  def status
    nil
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

  def serializer_class
    ::WorkQueue::AppealSerializer
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

  def vsos
    vso_participant_ids = power_of_attorneys.map(&:participant_id)
    Vso.where(participant_id: vso_participant_ids)
  end

  def external_id
    uuid
  end

  def create_tasks_on_intake_success!
    RootTask.create_root_and_sub_tasks!(self)
    create_business_line_tasks if request_issues.any?(&:requires_record_request_task?)
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
    RootTask.find_by(appeal_id: id)
  end

  # needed for appeal status api
  def appeal_status_id
    "A#{id}"
  end

  def linked_review_ids
    Array.wrap(appeal_status_id)
  end

  def active_status?
    active? || active_ep? || active_remanded_claims?
  end

  def active_ep?
    decision_document&.end_product_establishments&.any? { |ep| ep.status_active?(sync: false) }
  end

  def location
    if active_ep? || active_remanded_claims?
      "aoj"
    else
      "bva"
    end
  end

  def status_hash
    { type: fetch_status, details: fetch_details_for_status }
  end

  def fetch_status
    if active?
      fetch_pre_decision_status
    else
      fetch_post_decision_status
    end
  end

  # rubocop:disable CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
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
    elsif effectuation_ep? && !active_ep?
      :bva_decision_effectuation
    elsif decision_issues.any?
      :bva_decision
    elsif withdrawn?
      :withdrawn
    else decision_issues.empty?
         :other_close
    end
  end
  # rubocop:enable CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  # rubocop:disable Metrics/MethodLength
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
        bvaDecisionDate: decision_event_date,
        aojDecisionDate: decision_effectuation_event_date
      }
    when :pending_hearing_scheduling
      {
        type: "video"
      }
    else
      {}
    end
  end
  # rubocop:enable Metrics/MethodLength

  def post_bva_dta_decision_status_details
    issue_list = remanded_sc_decision_issues
    {
      issues: api_issues_for_status_details_issues(issue_list),
      bvaDecisionDate: decision_event_date,
      aojDecisionDate: remand_decision_event_date
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
    tasks.active.where(type: ScheduleHearingTask.name).any?
  end

  def hearing_pending?
    # This isn't available yet.
    # tasks.active.where(type: HoldHearingTask.name).any?
  end

  def evidence_submission_hold_pending?
    tasks.active.where(type: EvidenceSubmissionWindowTask.name).any?
  end

  def at_vso?
    # This task is always open, this can be used once that task is completed
    # tasks.active.where(type: InformalHearingPresentationTask.name).any?
  end

  def distributed_to_a_judge?
    tasks.any? { |t| t.is_a?(JudgeTask) }
  end

  def withdrawn?
    # will implement when available
  end

  def alerts
    # to be implemented
  end

  def aoj
    return "other" unless all_request_issues_same_aoj?

    request_issues.first.api_aoj_from_benefit_type
  end

  def all_request_issues_same_aoj?
    request_issues.all? do |ri|
      ri.api_aoj_from_benefit_type == request_issues.first.api_aoj_from_benefit_type
    end
  end

  def program
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
    return unless request_issues.open.any?
    return if request_issues.any? { |ri| !ri.closed? && ri.decision_or_promulgation_date.nil? }

    open_request_issues = request_issues.find_all { |ri| !ri.closed? }
    oldest = open_request_issues.min_by(&:decision_or_promulgation_date)
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

  def first_distributed_to_judge_date
    judge_tasks = tasks.select { |t| t.is_a?(JudgeTask) }
    return unless judge_tasks.any?

    judge_tasks.min_by(&:created_at).created_at
  end

  def effectuation_ep?
    decision_document&.end_product_establishments&.any?
  end

  def decision_effectuation_event_date
    return if decision_issues.remanded.any?
    return unless effectuation_ep?
    return if active_ep?

    decision_document.end_product_establishments.first.last_synced_at.to_date
  end

  def other_close_event_date
    return if active_status?
    return if decision_issues.any?

    root_task.closed_at
  end

  def events
    @events ||= AppealEvents.new(appeal: self).all
  end

  def issues_hash
    issue_list = decision_issues.empty? ? request_issues.open : fetch_all_decision_issues

    fetch_issues_status(issue_list)
  end

  def fetch_all_decision_issues
    return decision_issues unless decision_issues.remanded.any?
    # only include the remanded issues if they are still being worked on
    return decision_issues if active_remanded_claims?

    super
  end

  private

  def most_recently_assigned_to_label(tasks)
    tasks.order(:updated_at).last.assigned_to_label
  end

  def maybe_create_translation_task
    veteran_state_code = veteran&.state
    va_dot_gov_address = veteran.validate_address
    state_code = va_dot_gov_address&.dig(:state_code) || veteran_state_code
  rescue Caseflow::Error::VaDotGovAPIError
    state_code = veteran_state_code
  ensure
    TranslationTask.create_from_root_task(root_task) if STATE_CODES_REQUIRING_TRANSLATION_TASK.include?(state_code)
  end

  def create_business_line_tasks
    request_issues.select(&:requires_record_request_task?).each do |req_issue|
      business_line = req_issue.business_line
      VeteranRecordRequest.create!(
        parent: root_task,
        appeal: self,
        assigned_at: Time.zone.now,
        assigned_to: business_line
      )
    end
  end

  def bgs
    BGSService.new
  end

  # we always want to show ratings on intake
  def can_contest_rating_issues?
    true
  end

  def contestable_decision_issues
    return [] unless receipt_date

    DecisionIssue.where(participant_id: veteran.participant_id)
      .select(&:finalized?)
      .select do |issue|
        issue.approx_decision_date && issue.approx_decision_date < receipt_date
      end
  end
end
# rubocop:enable Metrics/ClassLength
