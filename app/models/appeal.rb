class Appeal < DecisionReview
  include Taskable

  has_many :appeal_views, as: :appeal
  has_many :claims_folder_searches, as: :appeal

  # decision_documents is effectively a has_one until post decisional motions are supported
  has_many :decision_documents

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
  }

  # rubocop:disable Metrics/LineLength
  scope :all_nonpriority, lambda {
    join_aod_motions
      .where("people.date_of_birth > ?", 75.years.ago)
      .group("appeals.id")
      .having("count(case when advance_on_docket_motions.granted and advance_on_docket_motions.created_at > appeals.established_at then 1 end) = ?", 0)
  }
  # rubocop:enable Metrics/LineLength

  UUID_REGEX = /^\h{8}-\h{4}-\h{4}-\h{4}-\h{12}$/.freeze

  def document_fetcher
    @document_fetcher ||= DocumentFetcher.new(
      appeal: self, use_efolder: true
    )
  end

  delegate :documents, :number_of_documents, :manifest_vbms_fetched_at,
           :new_documents_for_user, :manifest_vva_fetched_at, to: :document_fetcher

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
  # rubocop:disable Metrics/PerceivedComplexity
  def location_code
    location_code = nil

    if root_task && root_task.status == Constants.TASK_STATUSES.completed
      location_code = COPY::CASE_LIST_TABLE_POST_DECISION_LABEL
    else
      active_tasks = tasks.where(status: [Constants.TASK_STATUSES.in_progress, Constants.TASK_STATUSES.assigned])
      if active_tasks == [root_task]
        location_code = COPY::CASE_LIST_TABLE_CASE_STORAGE_LABEL
      elsif !active_tasks.empty?
        most_recent_assignee = active_tasks.order(updated_at: :desc).first.assigned_to
        location_code = if most_recent_assignee.is_a?(Organization)
                          most_recent_assignee.name
                        else
                          most_recent_assignee.css_id
                        end
      end
    end

    location_code
  end
  # rubocop:enable Metrics/PerceivedComplexity

  def attorney_case_reviews
    tasks.map(&:attorney_case_reviews).flatten
  end

  def every_request_issue_has_decision?
    eligible_request_issues.all? { |request_issue| request_issue.decision_issues.present? }
  end

  def reviewing_judge_name
    task = tasks.order(:created_at).select { |t| t.is_a?(JudgeTask) }.last
    task ? task.assigned_to.try(:full_name) : ""
  end

  def eligible_request_issues
    # It's possible that two users create issues around the same time and the sequencer gets thrown off
    # (https://stackoverflow.com/questions/5818463/rails-created-at-timestamp-order-disagrees-with-id-order)
    request_issues.select(&:eligible?).sort_by(&:id)
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
    tasks.where(type: RootTask.name).where.not(status: Constants.TASK_STATUSES.completed).any?
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
           :country, to: :veteran, prefix: true

  def regional_office
    nil
  end

  def needs_ihp?
    # TODO: filter to only ihp-writing vsos
    # e.g. for hearing appeals it should only be PVA.
    vsos.present?
  end

  def advanced_on_docket
    claimants.any? { |claimant| claimant.advanced_on_docket(receipt_date) }
  end

  delegate :first_name, :last_name, :name_suffix, :ssn, to: :veteran, prefix: true, allow_nil: true

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
    # temporary until ticket for appeals benefit type by issue is implemented
    # https://github.com/department-of-veterans-affairs/caseflow/issues/5882
    "compensation"
  end

  def create_issues!(new_issues)
    new_issues.each do |issue|
      issue.update!(benefit_type: benefit_type, veteran_participant_id: veteran.participant_id)
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
  end

  # Only select completed tasks because incomplete tasks will appear elsewhere on case details page.
  # Tasks are sometimes assigned to organizations for tracking, these will appear as duplicates if they have child
  # tasks, so we do not return those organization tasks.
  def tasks_for_timeline
    tasks.where(status: Constants.TASK_STATUSES.completed).order("completed_at DESC")
      .reject { |t| t.assigned_to.is_a?(Organization) && t.children.pluck(:assigned_to_type).include?(User.name) }
  end

  def timeline
    [
      {
        title: decision_date ? COPY::CASE_TIMELINE_DISPATCHED_FROM_BVA : COPY::CASE_TIMELINE_DISPATCH_FROM_BVA_PENDING,
        date: decision_date
      },
      tasks_for_timeline.map(&:timeline_details),
      {
        title: receipt_date ? COPY::CASE_TIMELINE_NOD_RECEIVED : COPY::CASE_TIMELINE_NOD_PENDING,
        date: receipt_date
      }
    ].flatten
  end

  def establish!
    attempted!

    process_legacy_issues!

    clear_error!
    processed!
  end

  def outcoded?
    root_task && root_task.status == Constants.TASK_STATUSES.completed
  end

  def root_task
    RootTask.find_by(appeal_id: id)
  end

  private

  def bgs
    BGSService.new
  end
end
