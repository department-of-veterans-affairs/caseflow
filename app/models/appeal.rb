# frozen_string_literal: true

##
# An appeal filed by a Veteran or appellant to the Board of Veterans' Appeals for VA decisions on claims for benefits.
# This is the type of appeal created by the Veterans Appeals Improvement and Modernization Act (AMA),
# which went into effect Feb 19, 2019.

# rubocop:disable Metrics/ClassLength
class Appeal < DecisionReview
  include AppealConcern
  include BgsService
  include Taskable
  include PrintsTaskTree
  include HasTaskHistory
  include AppealAvailableHearingLocations
  include HearingRequestTypeConcern

  has_many :appeal_views, as: :appeal
  has_many :claims_folder_searches, as: :appeal
  has_many :hearings
  has_many :available_hearing_locations, as: :appeal, class_name: "AvailableHearingLocations"

  # decision_documents is effectively a has_one until post decisional motions are supported
  has_many :decision_documents, as: :appeal
  has_many :vbms_uploaded_documents
  has_many :remand_supplemental_claims, as: :decision_review_remanded, class_name: "SupplementalClaim"

  has_many :nod_date_updates

  has_one :special_issue_list
  has_one :post_decision_motion

  # The has_one here provides the docket_switch object to the newly created appeal upon completion of the docket switch
  has_one :docket_switch, class_name: "DocketSwitch", foreign_key: :new_docket_stream_id

  has_one :appellant_substitution, foreign_key: :target_appeal_id

  has_many :record_synced_by_job, as: :record
  has_one :work_mode, as: :appeal
  has_one :latest_informal_hearing_presentation_task, lambda {
    not_cancelled
      .order(closed_at: :desc, assigned_at: :desc)
      .where(type: [InformalHearingPresentationTask.name, IhpColocatedTask.name], appeal_type: Appeal.name)
  }, class_name: "Task", foreign_key: :appeal_id

  enum stream_type: {
    Constants.AMA_STREAM_TYPES.original.to_sym => Constants.AMA_STREAM_TYPES.original,
    Constants.AMA_STREAM_TYPES.vacate.to_sym => Constants.AMA_STREAM_TYPES.vacate,
    Constants.AMA_STREAM_TYPES.de_novo.to_sym => Constants.AMA_STREAM_TYPES.de_novo,
    Constants.AMA_STREAM_TYPES.court_remand.to_sym => Constants.AMA_STREAM_TYPES.court_remand
  }

  after_create :conditionally_set_aod_based_on_age

  after_save :set_original_stream_data

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

  def self.find_appeal_by_uuid_or_find_or_create_legacy_appeal_by_vacols_id(id)
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

  # rubocop:disable Metrics/MethodLength
  def create_stream(stream_type, new_claimants: nil)
    ActiveRecord::Base.transaction do
      Appeal.create!(slice(
        :aod_based_on_age,
        :closest_regional_office,
        :docket_type,
        :legacy_opt_in_approved,
        :receipt_date,
        :veteran_file_number,
        :veteran_is_not_claimant
      ).merge(
        stream_type: stream_type,
        stream_docket_number: docket_number,
        established_at: Time.zone.now
      )).tap do |stream|
        if new_claimants
          new_claimants.each { |claimant| claimant.update(decision_review: stream) }

          # Why isn't this a calculated value instead of stored in the DB?
          stream.update(veteran_is_not_claimant: !new_claimants.map(&:person).include?(veteran.person))
        else
          stream.copy_claimants!(claimants)
        end
        stream.reload # so that stream.claimants returns updated list
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

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

  delegate :program, to: :decorated_with_status

  delegate :distributed_to_a_judge?, to: :decorated_with_status

  def decorated_with_status
    AppealStatusApiDecorator.new(self)
  end

  def active_request_issues_or_decision_issues
    decision_issues.empty? ? active_request_issues : fetch_all_decision_issues
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
    active_request_issues.all? { |request_issue| request_issue.decision_issues.present? }
  end

  def latest_attorney_case_review
    return @latest_attorney_case_review if defined?(@latest_attorney_case_review)

    @latest_attorney_case_review = AttorneyCaseReview
      .where(task_id: tasks.pluck(:id))
      .order(:created_at).last
  end

  def reviewing_judge_name
    task = tasks.not_cancelled.of_type(:JudgeDecisionReviewTask).order(created_at: :desc).first
    task ? task.assigned_to.try(:full_name) : ""
  end

  def active_request_issues
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
    tasks.open.of_type(:RootTask).any?
  end

  def ready_for_distribution?
    tasks.active.of_type(:DistributionTask).any?
  end

  def ready_for_distribution_at
    tasks.select { |t| t.type == "DistributionTask" }.map(&:assigned_at).max
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

  def regional_office_key
    nil
  end

  def conditionally_set_aod_based_on_age
    return unless claimant # do not update if claimant is not yet set, i.e., when create_stream is called

    updated_aod_based_on_age = claimant&.advanced_on_docket_based_on_age?
    update(aod_based_on_age: updated_aod_based_on_age) if aod_based_on_age != updated_aod_based_on_age
  end

  def advanced_on_docket?
    conditionally_set_aod_based_on_age
    # One of the AOD motion reasons is 'age'. Keep interrogation of any motions separate from `aod_based_on_age`,
    # which reflects `claimant.advanced_on_docket_based_on_age?`.
    aod_based_on_age || claimant&.advanced_on_docket_motion_granted?(self)
  end

  # Prefer aod? over aod going forward, as this function returns a boolean
  alias aod? advanced_on_docket?
  alias aod advanced_on_docket?

  delegate :first_name,
           :middle_name,
           :last_name,
           :name_suffix, to: :veteran, prefix: true, allow_nil: true

  alias appellant claimant

  delegate :first_name,
           :middle_name,
           :last_name,
           :name_suffix,
           :address_line_1,
           :city,
           :zip,
           :state,
           :email_address, to: :appellant, prefix: true, allow_nil: true

  def appellant_tz
    return if address.blank?

    # Use an address object if this is a hash
    appellant_address = address.is_a?(Hash) ? Address.new(address) : address

    begin
      TimezoneService.address_to_timezone(appellant_address).identifier
    rescue StandardError => error
      Raven.capture_exception(error)
      nil
    end
  end

  def representative_tz
    return if representative_address.blank?

    # Use an address object if this is a hash
    rep_address = representative_address.is_a?(Hash) ? Address.new(representative_address) : representative_address

    begin
      TimezoneService.address_to_timezone(rep_address).identifier
    rescue StandardError => error
      Raven.capture_exception(error)
      nil
    end
  end

  def appellant_middle_initial
    appellant_middle_name&.first
  end

  def appellant_is_not_veteran
    !!veteran_is_not_claimant
  end

  def veteran_middle_initial
    veteran_middle_name&.first
  end

  # matches Legacy behavior
  def cavc
    court_remand?
  end

  alias cavc? cavc

  def cavc_remand
    return nil if !cavc?

    # If this appeal is a direct result of a CavcRemand, then return it
    return CavcRemand.find_by(remand_appeal: self) if CavcRemand.find_by(remand_appeal: self)

    # If this appeal went through appellant_substitution after a CavcRemand, then use the source_appeal,
    # which is the same stream_type (cavc? == true) as this appeal.
    appellant_substitution.source_appeal.cavc_remand if appellant_substitution?
  end

  def appellant_substitution?
    !!appellant_substitution
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

  def create_issues!(new_issues, _request_issues_update = nil)
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

    default_docket_number_from_receipt_date
  end

  def update_receipt_date!(receipt_date)
    update!(receipt_date)
    update!(stream_docket_number: default_docket_number_from_receipt_date)
  end

  def untimely_issues_report(new_date)
    affected_issues = active_request_issues.reject { |request_issue| request_issue.timely_issue?(new_date.to_date) }
    unaffected_issues = active_request_issues - affected_issues

    return if affected_issues.blank?

    issues_report = {
      affected_issues: affected_issues,
      unaffected_issues: unaffected_issues
    }

    issues_report
  end

  # Currently AMA only supports one claimant per decision review
  def power_of_attorney
    claimant&.power_of_attorney
  end

  delegate :representative_name,
           :representative_type,
           :representative_address,
           :representative_email_address,
           :poa_last_synced_at,
           :update_cached_attributes!,
           :save_with_updated_bgs_record!,
           to: :power_of_attorney, allow_nil: true

  def power_of_attorneys
    claimants.map(&:power_of_attorney).compact
  end

  def representatives
    vso_participant_ids = power_of_attorneys.map(&:participant_id).compact.uniq
    # TODO: add index
    # Representatives are returned for Vso or PrivateBar POAs (i.e., subclasses of Representative)
    # and typically not for POAs with `BgsPowerOfAttorney.representative_type` = 'Agent' or 'Attorney'.
    # To get all POAs, call `power_of_attorneys`.
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

  # Stream change tasks indicate tasks that _may_ be moved to another appeal stream during a docket switch
  # This includes open children tasks with no children, excluding docket related tasks
  def docket_switchable_tasks
    tasks.select(&:can_move_on_docket_switch?)
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

    @finalized_decision_issues_before_receipt_date ||= begin
      DecisionIssue.includes(:decision_review).where(participant_id: veteran.participant_id)
        .select(&:finalized?)
        .select do |issue|
          issue.approx_decision_date && issue.approx_decision_date < receipt_date
        end
    end
  end

  def create_business_line_tasks!
    business_lines_needing_assignment.each do |business_line|
      if business_line.nil? || business_line.name.blank?
        fail Caseflow::Error::MissingBusinessLine
      end

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

  # We are ready for BVA dispatch if
  #  - the appeal is not at Quality Review
  #  - the appeal has not already completed BVA Dispatch
  #  - the appeal is not already at BVA Dispatch
  #  - the appeal is not at Judge Decision Review
  #  - the appeal has a finished Judge Decision Review
  def ready_for_bva_dispatch?
    return false if Task.open.where(appeal: self).where("type IN (?, ?, ?)",
                                                        JudgeDecisionReviewTask.name,
                                                        QualityReviewTask.name,
                                                        BvaDispatchTask.name).any?
    return false if BvaDispatchTask.completed.find_by(appeal: self)
    return true if JudgeDecisionReviewTask.completed.find_by(appeal: self)

    false
  end

  # This method allows the old appeal stream to access the docket_switch objects
  # rubocop:disable all
  def switched_dockets
    DocketSwitch.where(old_docket_stream_id: self.id)
  end

  def appellant_relationship
    appellant&.relationship
  end

  private

  def business_lines_needing_assignment
    request_issues.select(&:requires_record_request_task?).map(&:business_line).uniq
  end

  # If any database fields need populating after the first save, e.g. because we
  # know the new ID, immediately do a second save! so the record is accurate.
  def set_original_stream_data
    self.stream_docket_number ||= docket_number if receipt_date
    self.stream_type ||= type.parameterize.underscore.to_sym
    save! if has_changes_to_save? # prevent infinite recursion
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

  def default_docket_number_from_receipt_date
    "#{receipt_date.strftime('%y%m%d')}-#{id}"
  end
end
# rubocop:enable Metrics/ClassLength
