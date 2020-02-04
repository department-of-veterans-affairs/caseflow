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
  include AppealAvailableHearingLocations

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

  enum stream_type: {
    "original": "original",
    "vacate": "vacate",
    "de_novo": "de_novo"
  }

  before_save :set_stream_docket_number_and_stream_type

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

  scope :established, -> { where.not(established_at: nil) }

  UUID_REGEX = /^\h{8}-\h{4}-\h{4}-\h{4}-\h{12}$/.freeze
  STATE_CODES_REQUIRING_TRANSLATION_TASK = %w[VI VQ PR PH RP PI].freeze

  alias_attribute :nod_date, :receipt_date # LegacyAppeal parity

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
    Intake::AppealSerializer.new(self).serializable_hash[:data][:attributes]
  end

  def type
    stream_type&.titlecase || "Original"
  end

  def create_stream(stream_type)
    ActiveRecord::Base.transaction do
      Appeal.create!(slice(
        :receipt_date,
        :veteran_file_number,
        :legacy_opt_in_approved,
        :veteran_is_not_claimant
      ).merge(stream_type: stream_type, stream_docket_number: docket_number)).tap do |stream|
        stream.create_claimant!(participant_id: claimant.participant_id, payee_code: claimant.payee_code)
      end
    end
  end

  def vacate_type
    return nil unless vacate?

    post_decision_motion&.vacate_type
  end

  # Returns the most directly responsible party for an appeal when it is at the Board,
  # mirroring Legacy Appeals' location code in VACOLS
  def assigned_to_location
    return COPY::CASE_LIST_TABLE_POST_DECISION_LABEL if root_task&.status == Constants.TASK_STATUSES.completed

    recently_updated_task = Task.any_recently_updated(
      tasks.active.visible_in_queue_table_view,
      tasks.on_hold.visible_in_queue_table_view
    )
    return recently_updated_task.assigned_to_label if recently_updated_task

    # this condition is no longer needed since we only want active or on hold tasks
    return tasks.most_recently_updated&.assigned_to_label if tasks.any?

    decorated_with_status.fetch_status.to_s.titleize
  end

  def program
    decorated_with_status.program
  end

  def distributed_to_a_judge?
    decorated_with_status.distributed_to_a_judge?
  end

  def decorated_with_status
    AppealStatusApiDecorator.new(self)
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
           :email_address,
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
    claimant&.advanced_on_docket?(receipt_date)
  end

  # Prefer aod? over aod going forward, as this function returns a boolean
  alias aod? advanced_on_docket?
  alias aod advanced_on_docket?

  delegate :first_name,
           :last_name,
           :name_suffix, to: :veteran, prefix: true, allow_nil: true

  alias appellant claimant

  delegate :first_name,
           :last_name,
           :middle_name,
           :name_suffix,
           :address_line_1,
           :city,
           :zip,
           :state, to: :appellant, prefix: true, allow_nil: true

  def appellant_is_not_veteran
    !!veteran_is_not_claimant
  end

  def cavc
    "not implemented for AMA"
  end

  def status
    @status ||= BVAAppealStatus.new(appeal: self)
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
      issue.handle_legacy_issues!
    end
    request_issues.reload
  end

  def docket_number
    return stream_docket_number if stream_docket_number
    return "Missing Docket Number" unless receipt_date && persisted?

    "#{receipt_date.strftime('%y%m%d')}-#{id}"
  end

  # Currently AMA only supports one claimant per decision review
  def power_of_attorney
    claimant&.power_of_attorney
  end

  delegate :representative_name,
           :representative_type,
           :representative_address,
           :representative_email_address,
           to: :power_of_attorney, allow_nil: true

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

  def processed_in_caseflow?
    true
  end

  def processed_in_vbms?
    false
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

  def set_stream_docket_number_and_stream_type
    if receipt_date && persisted?
      self.stream_docket_number ||= docket_number
    end
    self.stream_type ||= type.parameterize.underscore.to_sym
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

  # Non-vacate Appeals are not expected to have a PDM, but this method makes a
  # best-effort attempt in either situation, and returns nil if none is found.
  def post_decision_motion
    PostDecisionMotion.where(task: tasks).first
  end
end
