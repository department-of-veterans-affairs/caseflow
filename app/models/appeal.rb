# frozen_string_literal: true

require "securerandom"

##
# An appeal filed by a Veteran or appellant to the Board of Veterans' Appeals for VA decisions on claims for benefits.
# This is the type of appeal created by the Veterans Appeals Improvement and Modernization Act (AMA),
# which went into effect Feb 19, 2019.

# rubocop:disable Metrics/ClassLength
class Appeal < DecisionReview
  include AppealConcern
  include BeaamAppealConcern
  include BgsService
  include Taskable
  include PrintsTaskTree
  include HasTaskHistory
  include AppealAvailableHearingLocations
  include HearingRequestTypeConcern
  include AppealNotificationReportConcern
  prepend AppealDocketed

  has_many :appeal_views, as: :appeal
  has_many :claims_folder_searches, as: :appeal
  has_many :hearings
  has_many :email_recipients, class_name: "HearingEmailRecipient"
  has_many :available_hearing_locations, as: :appeal, class_name: "AvailableHearingLocations"
  has_many :vbms_uploaded_documents, as: :appeal

  # decision_documents is effectively a has_one until post decisional motions are supported
  has_many :decision_documents, as: :appeal
  has_many :remand_supplemental_claims, as: :decision_review_remanded, class_name: "SupplementalClaim"
  has_many :nod_date_updates
  has_one :special_issue_list, as: :appeal
  has_one :post_decision_motion

  # Each appeal has one appeal_state that is used for tracking quarterly notifications
  has_one :appeal_state, as: :appeal

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

  delegate :power_of_attorney, to: :claimant
  delegate :representative_name,
           :representative_type,
           :representative_address,
           :representative_email_address,
           :poa_last_synced_at,
           :update_cached_attributes!,
           :save_with_updated_bgs_record!,
           to: :power_of_attorney, allow_nil: true

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
    validates :homelessness, inclusion: { in: [true, false], message: "blank" }
    validates_associated :claimants
  end

  # error for already split issue
  class IssueAlreadyDuplicated < StandardError; end

  scope :active, lambda {
    joins(:tasks)
      .group("appeals.id")
      .having("count(case when tasks.type = ? and tasks.status not in (?) then 1 end) >= ?",
              RootTask.name, Task.closed_statuses, 1)
  }

  scope :pre_docket, lambda {
    joins(:tasks)
      .group("appeals.id")
      .having("count(case when tasks.type = ? and tasks.status not in (?) then 1 end) >= ?",
              PreDocketTask.name, Task.closed_statuses, 1)
  }

  scope :established, -> { where.not(established_at: nil) }

  scope :non_deceased_appellants, lambda {
    joins("INNER JOIN veterans ON veterans.file_number = appeals.veteran_file_number")
      .where("veterans.date_of_death is null OR (veterans.date_of_death is not null
        AND veteran_is_not_claimant = true)")
  }

  scope :has_substitute_appellant, lambda {
    joins("INNER JOIN veterans ON veterans.file_number = appeals.veteran_file_number")
      .where("veterans.date_of_death is not null AND veteran_is_not_claimant = true")
  }

  UUID_REGEX = /^\h{8}-\h{4}-\h{4}-\h{4}-\h{12}$/.freeze

  alias_attribute :nod_date, :receipt_date # LegacyAppeal parity
  attr_accessor :duplicate_split_appeal, :original_split_appeal, :appeal_split_process

  # amoeba gem for splitting appeals
  amoeba do
    enable
    # lambda for setting up a new UUID for the appeal first
    override(lambda { |_, dup_appeal|
      # set the UUID to nil so that it is auto generated
      dup_appeal.uuid = nil
      # generate UUIDs
      dup_appeal.uuid = SecureRandom.uuid
      # make sure the uuid doesn't exist in the database (by some chance)
      while Appeal.find_by_uuid(dup_appeal.uuid).nil? == false
        # generate new id if not
        dup_appeal.uuid = SecureRandom.uuid
      end

      # set appeal_split_process to turn off validation while the appeal
      # split is happening.
      dup_appeal.appeal_split_process = true
    })

    include_association :appeal_views
    include_association :appellant_substitution
    include_association :attorney_case_reviews
    include_association :available_hearing_locations
    include_association :special_issue_list
    include_association :docket_switch
    include_association :record_synced_by_job
    include_association :request_issues_updates
    include_association :intake
    include_association :claimants
    include_association :remand_supplemental_claims
    include_association :claims_folder_searches
    include_association :judge_case_reviews
    include_association :nod_date_updates
    include_association :work_mode

    # lambda for setting up a new UUID for supplemental claims
    customize(lambda { |_, dup_appeal|
      # set the UUID to nil so that it is auto generated
      dup_sup_claims = dup_appeal.remand_supplemental_claims

      dup_sup_claims.each do |sm_claim|
        sm_claim.uuid = nil
        sm_claim.uuid = SecureRandom.uuid

        # make sure uuid doesn't exist in the database (by some chance)
        while SupplementalClaim.find_by(uuid: sm_claim.uuid).nil? == false
          sm_claim.uuid = SecureRandom.uuid
        end
      end
    })
  end

  def hearing_day_if_schedueled
    hearing_date = Hearing.find_by(appeal_id: id)

    if hearing_date.nil?
      return nil

    else
      return hearing_date.hearing_day.scheduled_for
    end
  end

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

  def contested_claim?
    return false unless FeatureToggle.enabled?(:indicator_for_contested_claims)

    category_substrings = %w[Contested Apportionment]

    request_issues.active.any? do |request_issue|
      category_substrings.any? { |substring| self.request_issues.active.include?(request_issue) && request_issue.nonrating_issue_category&.include?(substring) }
    end
  end

  def mst?
    return false unless FeatureToggle.enabled?(:mst_pact_identification)

    request_issues.active.any?(&:mst_status) ||
      (special_issue_list && special_issue_list.created_at < "2023-06-01".to_date && special_issue_list.military_sexual_trauma)
  end

  def pact?
    return false unless FeatureToggle.enabled?(:mst_pact_identification)

    request_issues.active.any?(&:pact_status)
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

  def every_request_issue_has_decision?
    active_request_issues.all? { |request_issue| request_issue.decision_issues.present? }
  end

  def reviewing_judge_name
    task = tasks.not_cancelled.of_type(:JudgeDecisionReviewTask).order(:created_at).last
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

  # finalize_split_appeal contains all the methods to finish the amoeba split
  def finalize_split_appeal(parent_appeal, params)
    # update the child task tree with parent, passing CSS ID of user for validation
    self&.clone_task_tree(parent_appeal, params[:user_css_id])
    # clone the hearings and hearing relations from parent appeal
    self&.clone_hearings(parent_appeal)
    # if there are ihp drafts, clone them too
    self&.clone_ihp_drafts(parent_appeal)
    # if there are cavc_remand, clone them too (need user css id)
    self&.clone_cavc_remand(parent_appeal, params[:user_css_id])
    # clones request_issues, decision_issues, and request_decision_issues
    self&.clone_issues(parent_appeal, params)
    # if there is an AOD for the parent appeal, clone
    if !AdvanceOnDocketMotion.find_by(appeal_id: parent_appeal.id).nil?
      self&.clone_aod(parent_appeal)
    end
    # set split appeal process flag to false
    self.appeal_split_process = false
    # set the duplication split flag
    self.duplicate_split_appeal = true
    # set the parent original split appeal flat
    parent_appeal.original_split_appeal = true
  end

  # clones cavc_remand. Uses user_css_id that did the split to complete the remand split
  def clone_cavc_remand(parent_appeal, user_css_id)
    # get cavc remand from the parent appeal
    original_remand = parent_appeal.cavc_remand
    # clone w error handling
    dup_remand = original_remand&.amoeba_dup
    # set appeal id to remand_appeal_id
    dup_remand&.remand_appeal_id = id
    # set source appeal id to parent appeal
    dup_remand&.source_appeal = parent_appeal
    # set request store to the user that split the appeal
    RequestStore[:current_user] = User.find_by_css_id user_css_id
    # save
    dup_remand&.save
  end

  # clone issues clones request_issues the user selected
  # and anydecision_issues/decision_request_issues tied to the request issue
  def clone_issues(parent_appeal, payload_params)
    # set request store to the user that split the appeal
    RequestStore[:current_user] = User.find_by_css_id payload_params[:user_css_id]

    # cycle the split_request_issues list from the payload
    payload_params[:appeal_split_issues].each do |r_issue_id|
      # find the request issue from the parent appeal
      r_issue = parent_appeal.request_issues.find(r_issue_id.to_i)

      # fail/revert changes if the issue was already duplicated
      fail IssueAlreadyDuplicated if r_issue.split_issue_status == "on_hold"

      dup_r_issue = clone_issue(r_issue)

      # create Split Correlation table record to document split request issue relations
      SplitCorrelationTable.create!(
        appeal_id: id,
        appeal_type: docket_type,
        appeal_uuid: uuid,
        created_at: Time.zone.now.utc,
        created_by_id: RequestStore[:current_user].id,
        original_appeal_id: parent_appeal.id,
        original_appeal_uuid: parent_appeal.uuid,
        original_request_issue_id: r_issue.id,
        relationship_type: "split_appeal",
        split_other_reason: payload_params[:split_other_reason],
        split_reason: payload_params[:split_reason],
        split_request_issue_id: dup_r_issue.id,
        updated_at: Time.zone.now.utc,
        updated_by_id: RequestStore[:current_user].id,
        working_split_status: Constants.TASK_STATUSES.in_progress
      )

      # set original issue on hold and duplicate issue to in_progress
      r_issue.update!(
        split_issue_status: Constants.TASK_STATUSES.on_hold
      )
      r_issue.save!
      dup_r_issue.update!(
        split_issue_status: Constants.TASK_STATUSES.in_progress
      )
      dup_r_issue.save!

      # skip copying decision issues if there aren't any
      next if r_issue.request_decision_issues.empty?

      # copy the request_decision_issues
      r_issue.request_decision_issues.each do |rd_issue|
        clone_request_decision_issue(rd_issue, dup_r_issue)
      end
    end
  end

  def clone_aod(parent_appeal)
    # find the appeal AOD
    aod = AdvanceOnDocketMotion.find_by(appeal_id: parent_appeal.id)
    # create a new advance on docket for the duplicate appeal
    AdvanceOnDocketMotion.create!(
      user_id: aod.user_id,
      person_id: claimant.person.id,
      granted: aod.granted,
      reason: aod.reason,
      appeal: self
    )
  end

  def clone_issue(issue)
    dup_issue = issue.amoeba_dup
    dup_issue.decision_review_id = id
    dup_issue.save
    dup_issue
  end

  def clone_request_decision_issue(rd_issue, dup_r_issue)
    # get the decision issue id
    decision_issue_id = rd_issue.decision_issue_id
    # get the decision issue
    d_issue = DecisionIssue.find(decision_issue_id)
    # clone decision issue
    dup_d_issue = clone_issue(d_issue)
    # clone request_decision_issue
    dup_rd_issue = rd_issue.amoeba_dup
    # set the request_issue_id and decision_issue_id
    dup_rd_issue.request_issue_id = dup_r_issue.id
    dup_rd_issue.decision_issue_id = dup_d_issue.id
    dup_rd_issue.save!
  end

  def clone_ihp_drafts(parent_appeal)
    # get the list of ihp_drafts from the appeal
    original_ihp_drafts = IhpDraft.where(appeal_id: parent_appeal.id)
    # for each ihp_draft, amoeba clone it
    original_ihp_drafts.each do |draft|
      # clone draft
      dup_draft = draft&.amoeba_dup
      # set the appeal_id to this appeal
      dup_draft&.appeal_id = id
      # save the clone
      dup_draft&.save
    end
  end

  def clone_hearings(parent_appeal)
    parent_appeal.hearings.each do |hearing|
      # clone hearing
      dup_hearing = hearing&.amoeba_dup
      # assign to current appeal
      dup_hearing&.appeal_id = id

      # set split process on dup_hearing
      dup_hearing.appeal.appeal_split_process = true
      dup_hearing&.save
    end
  end

  def clone_task_tree(parent_appeal, user_css_id)
    # get the task tree from the parent
    parent_ordered_tasks = parent_appeal.tasks.order(:created_at)
    # define hash to store parent/child relationship values
    task_parent_to_child_hash = {}

    while parent_appeal.tasks.count != tasks.count && !parent_appeal.tasks.nil?
      # cycle each task in the parent
      parent_ordered_tasks.each do |task|
        # skip this task if the task has been copied (already in the hash)
        next if task_parent_to_child_hash.key?(task.id)

        # if the value has a parent and isn't in the dictionary, try to find it in the dictionary or else skip it
        if !task.parent_id.nil?
          # if the parent value hasn't been created, skip
          next if !task_parent_to_child_hash.key?(task.parent_id)

          # otherwise reassign old parent task to new from hash
          cloned_task_id = clone_task_w_parent(task, task_parent_to_child_hash[task.parent_id])

        else
          # else create the task that doesn't have a parent
          cloned_task_id = clone_task(task, user_css_id)
        end
        # add the parent/clone id to the hash set
        task_parent_to_child_hash[task.id] = cloned_task_id

        # break if the tree count is the same
        break if parent_appeal.tasks.count == tasks.count
      end
      # break if the tree count is the same
      break if parent_appeal.tasks.count == tasks.count
    end
  end

  # clone_task is used for splitting an appeal, tie to css_id for split
  def clone_task(original_task, user_css_id)
    # clone the task
    dup_task = original_task.amoeba_dup

    # assign the task to this appeal
    dup_task.appeal_id = id

    # set the status to assigned as placeholder
    dup_task.status = "assigned"

    # set the appeal split process to true for the task
    dup_task.appeal.appeal_split_process = true

    # save the task
    dup_task.save

    # set the status to the correct status
    dup_task.status = original_task.status

    # set request store to the user that split the appeal
    RequestStore[:current_user] = User.find_by_css_id user_css_id

    dup_task.save

    # return the task id to be added to the dict
    dup_task.id
  end

  def clone_task_w_parent(original_task, parent_task_id)
    # clone the task
    dup_task = original_task.amoeba_dup

    # assign the task to this appeal
    dup_task.appeal_id = id

    # set the status to assigned as placeholder
    dup_task.status = "assigned"

    # set the parent to the parent_task_id
    dup_task.parent_id = parent_task_id

    # set the appeal split process to true for the task
    dup_task.appeal.appeal_split_process = true

    # save the task
    dup_task.save(validate: false)

    # set the status to the correct status
    dup_task.status = original_task.status

    dup_task.save(validate: false)

    # if the status is cancelled, pull the original canceled ID
    if dup_task.status == "cancelled" && !original_task.cancelled_by_id.nil?

      # set request store to original task canceller to handle verification
      RequestStore[:current_user] = User.find(original_task.cancelled_by_id)

      # confirm task just in case no prompt
      dup_task.cancelled_by_id = original_task.cancelled_by_id
      dup_task.save(validate: false)
    end

    # return the task id to be added to the dict
    dup_task.id
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
    tasks.select { |task| task.type == "DistributionTask" }.map(&:assigned_at).max
  end

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

  def appellant_address
    appellant&.address
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

  def vha_predocket_needed?
    request_issues.active.any?(&:vha_predocket?)
  end

  def edu_predocket_needed?
    request_issues.active.any?(&:education_predocket?)
  end

  def caregiver_has_issues?
    request_issues.active.any? { |ri| ri.nonrating_issue_category =~ /Caregiver/ }
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

  # Determine if we are on a separate substitution appeal (used in serializer)
  def separate_appeal_substitution?
    appellant_substitution && id != appellant_substitution.source_appeal.id
  end

  # This method allows the source appeal stream to access the appellant_substitution objects
  def substitutions
    AppellantSubstitution.where(source_appeal_id: id)
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

  # :reek:FeatureEnvy
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

  def bgs_power_of_attorney
    claimant&.is_a?(BgsRelatedClaimant) ? power_of_attorney : nil
  end

  # Note: Currently Caseflow only supports one claimant per decision review
  def power_of_attorneys
    claimants.map(&:power_of_attorney).compact
  end

  def representatives
    vso_participant_ids = power_of_attorneys.map(&:participant_id).compact.uniq
    # Representatives are returned for Vso or PrivateBar POAs (i.e., subclasses of Representative)
    # and typically not for POAs with `BgsPowerOfAttorney.representative_type` = 'Agent' or 'Attorney'.
    # To get all POAs, call `power_of_attorneys`.
    Representative.where(participant_id: vso_participant_ids)
  end

  def external_id
    uuid
  end

  def create_tasks_on_intake_success!
    if vha_predocket_needed?
      PreDocketTasksFactory.new(self).call_vha
    elsif edu_predocket_needed?
      PreDocketTasksFactory.new(self).call_edu
    else
      InitialTasksFactory.new(self).create_root_and_sub_tasks!
    end
    create_business_line_tasks!
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
      update!(target_decision_date: receipt_date + Constants.DISTRIBUTION.direct_docket_time_goal.days)
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

  # :reek:FeatureEnvy
  def can_redistribute_appeal?
    relevant_tasks = tasks.reject do |task|
      task.is_a?(TrackVeteranTask) || task.is_a?(RootTask) ||
        task.is_a?(JudgeAssignTask) || task.is_a?(DistributionTask)
    end
    return false if relevant_tasks.any?(&:open?)
    return true if relevant_tasks.all?(&:closed?)
  end

  def is_legacy?
    false
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

  def default_docket_number_from_receipt_date
    "#{receipt_date.strftime('%y%m%d')}-#{id}"
  end
end
# rubocop:enable Metrics/ClassLength
