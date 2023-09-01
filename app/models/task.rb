# frozen_string_literal: true

##
# Base model for all tasks in generic organizational task queues in Caseflow
# Tasks represent work to be done by judges, attorneys, VSOs, and anyone else who touches a Veteran's appeal.
# Supports common actions like:
#   - marking tasks complete
#   - assigning a task to a team
#   - assigning a task to an individual

# rubocop:disable Metrics/ClassLength
class Task < CaseflowRecord
  has_paper_trail on: [:update, :destroy]
  acts_as_tree

  include PrintsTaskTree
  include TaskExtensionForHearings
  include HasAppealUpdatedSince

  belongs_to :assigned_to, polymorphic: true
  belongs_to :assigned_by, class_name: "User"
  belongs_to :cancelled_by, class_name: "User"
  belongs_to :completed_by, class_name: "User"

  include BelongsToPolymorphicAppealConcern
  belongs_to_polymorphic_appeal :appeal, include_decision_review_classes: true

  has_many :attorney_case_reviews, dependent: :destroy
  has_many :task_timers, dependent: :destroy
  has_one :cached_appeal, ->(task) { where(appeal_type: task.appeal_type) }, foreign_key: :appeal_id

  validates :assigned_to, :appeal, :type, :status, presence: true
  validate :status_is_valid_on_create, on: :create
  validate :assignee_status_is_valid_on_create, on: :create
  validate :parent_can_have_children

  before_create :set_assigned_at
  before_create :verify_org_task_unique

  after_create :create_and_auto_assign_child_task, if: :automatically_assign_org_task?
  after_create :tell_parent_task_child_task_created
  after_create :update_appeal_state_on_task_creation

  before_save :set_timestamp

  before_update :set_cancelled_by_id, if: :task_will_be_cancelled?
  after_update :update_parent_status, if: :task_just_closed_and_has_parent?
  after_update :update_children_status_after_closed, if: :task_just_closed?
  after_update :cancel_task_timers, if: :task_just_closed?
  after_update :update_appeal_state_on_status_change

  enum status: {
    Constants.TASK_STATUSES.assigned.to_sym => Constants.TASK_STATUSES.assigned,
    Constants.TASK_STATUSES.in_progress.to_sym => Constants.TASK_STATUSES.in_progress,
    Constants.TASK_STATUSES.on_hold.to_sym => Constants.TASK_STATUSES.on_hold,
    Constants.TASK_STATUSES.completed.to_sym => Constants.TASK_STATUSES.completed,
    Constants.TASK_STATUSES.cancelled.to_sym => Constants.TASK_STATUSES.cancelled
  }

  enum cancellation_reason: {
    Constants.TASK_CANCELLATION_REASONS.poa_change.to_sym => Constants.TASK_CANCELLATION_REASONS.poa_change,
    Constants.TASK_CANCELLATION_REASONS.substitution.to_sym => Constants.TASK_CANCELLATION_REASONS.substitution
  }

  amoeba do
    include_association :appeal_type
    include_association :assigned_by_id
    include_association :assigned_to_id
    include_association :assigned_to_type
    include_association :cancellation_reason
    include_association :cancelled_by_id
    include_association :closed_at
    include_association :instructions
    include_association :previous
    include_association :placed_on_hold_at
    include_association :started_at
    include_association :type
  end

  # This suppresses a warning about the :open scope overwriting the Kernel#open method
  # https://ruby-doc.org/core-2.6.3/Kernel.html#method-i-open
  class << self; undef_method :open; end

  scope :active, -> { where(status: active_statuses) }

  scope :open, -> { where(status: open_statuses) }

  scope :closed, -> { where(status: closed_statuses) }

  scope :not_cancelled, -> { where.not(status: Constants.TASK_STATUSES.cancelled) }

  scope :recently_completed, -> { completed.where(closed_at: (Time.zone.now - 1.week)..Time.zone.now) }

  scope :incomplete_or_recently_completed, -> { open.or(recently_completed) }

  scope :of_type, ->(task_type) { where(type: task_type) }

  scope :assigned_to_any_user, -> { where(assigned_to_type: "User") }
  scope :assigned_to_any_org, -> { where(assigned_to_type: "Organization") }

  # Equivalent to .reject(&:hide_from_queue_table_view) but offloads that to the database.
  scope :visible_in_queue_table_view, lambda {
    where.not(
      type: Task.descendants.select(&:hide_from_queue_table_view).map(&:name)
    )
  }

  scope :not_decisions_review, lambda {
                                 where.not(
                                   type: DecisionReviewTask.descendants.map(&:name) + ["DecisionReviewTask"]
                                 )
                               }

  scope :with_assignees, -> { joins(Task.joins_with_assignees_clause) }

  scope :with_assigners, -> { joins(Task.joins_with_assigners_clause) }

  scope :with_cached_appeals, -> { joins(Task.joins_with_cached_appeals_clause) }

  attr_accessor :skip_check_for_only_open_task_of_type

  prepend AppealDocketed
  prepend IhpTaskPending
  prepend IhpTaskComplete
  prepend IhpTaskCancelled
  prepend PrivacyActComplete
  prepend AppealCancelled
  prepend PrivacyActCancelled
  prepend PrivacyActPending

  ############################################################################################
  ## class methods
  class << self
    prepend PrivacyActPending

    # Task types used by RetrieveAndCacheReaderDocumentsJob
    # To cache docoments from VBMS to S3 for appeals
    # With taks that are likely to need Reader to complete
    READER_PRIORITY_TASK_TYPES = [JudgeAssignTask.name, JudgeDecisionReviewTask.name].freeze

    def reader_priority_task_types
      READER_PRIORITY_TASK_TYPES
    end

    def label
      name.titlecase
    end

    def closed_statuses
      [Constants.TASK_STATUSES.completed, Constants.TASK_STATUSES.cancelled]
    end

    def active_statuses
      [Constants.TASK_STATUSES.assigned, Constants.TASK_STATUSES.in_progress]
    end

    def open_statuses
      active_statuses.concat([Constants.TASK_STATUSES.on_hold])
    end

    def create_many_from_params(params_array, current_user)
      multi_transaction do
        params_array.map { |params| create_from_params(params, current_user) }
      end
    end

    def modify_params_for_create(params)
      if params.key?(:instructions) && !params[:instructions].is_a?(Array)
        params[:instructions] = [params[:instructions]]
      end
      params
    end

    def hide_from_queue_table_view
      false
    end

    def cannot_have_children
      false
    end

    def verify_user_can_create!(user, parent)
      can_create = parent&.available_actions(user)&.map do |action|
        parent.build_action_hash(action, user)
      end&.any? do |action|
        action.dig(:data, :type) == name || action.dig(:data, :options)&.any? { |option| option.dig(:value) == name }
      end
      if !parent&.actions_allowable?(user) || !can_create
        user_description = user ? "User #{user.id}" : "nil User"
        parent_description = parent ? " from #{parent.class.name} #{parent.id}" : ""
        message = "#{user_description} cannot assign #{name}#{parent_description}."
        fail Caseflow::Error::ActionForbiddenError, message: message
      end
    end

    def verify_user_can_create_legacy!(user, parent)
      can_create = parent&.available_actions(user, "SCM")&.map do |action|
        parent.build_action_hash(action, user)
      end&.any? do |action|
        action.dig(:data, :type) == name || action.dig(:data, :options)&.any? { |option| option.dig(:value) == name }
      end

      if !parent&.actions_allowable?(user) || !can_create
        user_description = user ? "User #{user.id}" : "nil User"
        parent_description = parent ? " from #{parent.class.name} #{parent.id}" : ""
        message = "#{user_description} cannot assign #{name}#{parent_description}."
        fail Caseflow::Error::ActionForbiddenError, message: message
      end
    end

    def child_task_assignee(_parent, params)
      Object.const_get(params[:assigned_to_type]).find(params[:assigned_to_id])
    end

    def child_assigned_by_id(parent, current_user)
      return current_user.id if current_user
      return parent.assigned_to_id if parent && parent.assigned_to_type == User.name
    end

    def most_recently_updated
      order(:updated_at).last
    end

    def any_recently_updated(*tasks_arrays)
      tasks_arrays.find(&:any?)&.most_recently_updated
    end

    def create_from_params(params, user)
      parent_task = create_parent_task(params, user)

      params = modify_params_for_create(params)

      if parent_task.appeal_type == "LegacyAppeal"
        special_case_for_legacy(parent_task, params, user)
      else # regular appeal
        child = create_child_task(parent_task, user, params)
        parent_task.update!(status: params[:status]) if params[:status]
        child
      end
    end

    def create_parent_task(params, user)
      parent_task = {}
      if (params[:appeal_type] == "LegacyAppeal") && (params[:legacy_task_type] == "AttorneyLegacyTask")
        if params[:type] == "SpecialCaseMovementTask" || params[:type] == "BlockedSpecialCaseMovementTask"
          parent_task = LegacyWorkQueue.tasks_by_appeal_id(params[:external_id])[0]
          verify_user_can_create_legacy!(user, parent_task)
          parent_task = Task.find(params[:parent_id])
        end
      else
        parent_task = Task.find(params[:parent_id])
        fail Caseflow::Error::ChildTaskAssignedToSameUser if parent_of_same_type_has_same_assignee(parent_task, params)

        verify_user_can_create!(user, parent_task)
      end
      parent_task
    end

    def special_case_for_legacy(parent_task, params, user)
      if (params[:type] == "SpecialCaseMovementTask") && (parent_task.type == "RootTask")
        create_judge_assigned_task_for_legacy(params, parent_task)
      elsif (params[:type] == "BlockedSpecialCaseMovementTask") && (parent_task.type == "HearingTask")
        cancel_blocking_task_legacy(params, parent_task)
      else
        judge = User.find(params["assigned_to_id"])
        legacy_appeal = LegacyAppeal.find(parent_task.appeal_id)
        child = create_child_task(parent_task, user, params)
        parent_task.update!(status: params[:status]) if params[:status]
        AppealRepository.update_location!(legacy_appeal, judge.vacols_uniq_id)
        child
      end
    end

    def create_parent_task(params, user)
      parent_task = {}
      if (params[:appeal_type] == "LegacyAppeal") && (params[:legacy_task_type] == "AttorneyLegacyTask")
        if params[:type] == "SpecialCaseMovementTask" || params[:type] == "BlockedSpecialCaseMovementTask"
          parent_task = LegacyWorkQueue.tasks_by_appeal_id(params[:external_id])[0]
          verify_user_can_create_legacy!(user, parent_task)
          parent_task = Task.find(params[:parent_id])
        end
      else
        parent_task = Task.find(params[:parent_id])
        fail Caseflow::Error::ChildTaskAssignedToSameUser if parent_of_same_type_has_same_assignee(parent_task, params)

        verify_user_can_create!(user, parent_task)
      end
      parent_task
    end

    def speacial_case_for_legacy(parent_task, params)
      if (params[:type] == "SpecialCaseMovementTask") && (parent_task.type == "RootTask")
        create_judge_assigned_task_for_legacy(params, parent_task)
      elsif (params[:type] == "BlockedSpecialCaseMovementTask") && (parent_task.type == "HearingTask")
        cancel_blocking_task_legacy(params, parent_task)
      end
    end

    def cancel_blocking_task_legacy(params, parent_task)
      tasks = []
      tasks.push(parent_task)
      parent_task.children.each { |current_task| tasks.push(current_task) }

      transaction do
        tasks.each do |task|
          task.update!(
            status: Constants.TASK_STATUSES.cancelled,
            cancelled_by_id: RequestStore[:current_user]&.id,
            closed_at: Time.zone.now
          )
        end
      end

      legacy_appeal = LegacyAppeal.find(tasks[0].appeal_id)
      judge = User.find(params["assigned_to_id"])

      current_child = JudgeAssignTask.create!(appeal: legacy_appeal,
                                              parent: legacy_appeal.root_task,
                                              assigned_to: judge,
                                              instructions: params[:instructions],
                                              assigned_by: params["assigned_by"])
      AppealRepository.update_location!(legacy_appeal, judge.vacols_uniq_id)
      current_child
    end

    def create_judge_assigned_task_for_legacy(params, parent_task)
      legacy_appeal = LegacyAppeal.find(parent_task.appeal_id)
      judge = User.find(params["assigned_to_id"])

      current_child = JudgeAssignTask.create!(appeal: legacy_appeal,
                                              parent: legacy_appeal.root_task,
                                              assigned_to: judge,
                                              instructions: params[:instructions],
                                              assigned_by: params["assigned_by"])
      AppealRepository.update_location!(legacy_appeal, judge.vacols_uniq_id)
      current_child
    end

    def parent_of_same_type_has_same_assignee(parent_task, params)
      parent_task.assigned_to_id == params[:assigned_to_id] &&
        parent_task.assigned_to_type == params[:assigned_to_type] &&
        parent_task.type == params[:type]
    end

    def create_child_task(parent, current_user, params)
      Task.create!(
        type: name,
        appeal: parent.appeal,
        assigned_by_id: child_assigned_by_id(parent, current_user),
        parent_id: parent.id,
        assigned_to: params[:assigned_to] || child_task_assignee(parent, params),
        instructions: params[:instructions],
        cancellation_reason: params[:cancellation_reason]
      )
    end

    def assigners_table_clause
      "(SELECT id, full_name AS display_name FROM users) AS assigners"
    end

    def joins_with_assigners_clause
      "LEFT JOIN #{Task.assigners_table_clause} ON assigners.id = tasks.assigned_by_id"
    end

    def assignees_table_clause
      "(SELECT id, 'Organization' AS type, name AS display_name FROM organizations " \
      "UNION " \
      "SELECT id, 'User' AS type, css_id AS display_name FROM users)" \
      "AS assignees"
    end

    def joins_with_assignees_clause
      "INNER JOIN #{Task.assignees_table_clause} ON " \
      "assignees.id = tasks.assigned_to_id AND assignees.type = tasks.assigned_to_type"
    end

    def joins_with_cached_appeals_clause
      "left join #{CachedAppeal.table_name} "\
      "on #{CachedAppeal.table_name}.appeal_id = #{Task.table_name}.appeal_id "\
      "and #{CachedAppeal.table_name}.appeal_type = #{Task.table_name}.appeal_type"
    end

    def order_by_appeal_priority_clause(order: "asc")
      boolean_order_clause = (order == "asc") ? "0 ELSE 1" : "1 ELSE 0"
      Arel.sql(
        "CASE WHEN #{CachedAppeal.table_name}.is_aod = TRUE THEN #{boolean_order_clause} END, "\
        "CASE WHEN #{CachedAppeal.table_name}.case_type = 'Court Remand' THEN #{boolean_order_clause} END, "\
        "#{CachedAppeal.table_name}.docket_number #{order}, "\
        "#{Task.table_name}.created_at #{order}"
      )
    end

    # Sorting tasks by docket number within each category of appeal: case type, aod, docket number
    # Used by ScheduleHearingTaskPager and WarmBgsCachedJob to sort ScheduleHearingTasks
    def order_by_cached_appeal_priority_clause
      Arel.sql(<<-SQL)
        (CASE
          WHEN cached_appeal_attributes.case_type = 'Court Remand' THEN 1
          ELSE 0
        END) DESC,
        cached_appeal_attributes.is_aod DESC,
        cached_appeal_attributes.docket_number ASC
      SQL
    end
  end

  ########################################################################################
  ## instance methods

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/AbcSize
  def available_actions(user)
    return [] unless user

    if assigned_to == user
      return [
        Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h,
        Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h,
        Constants.TASK_ACTIONS.TOGGLE_TIMED_HOLD.to_h,
        Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
        Constants.TASK_ACTIONS.CANCEL_TASK.to_h
      ]
    end

    if task_is_assigned_to_user_within_organization?(user)
      return [
        Constants.TASK_ACTIONS.REASSIGN_TO_PERSON.to_h
      ]
    end

    if task_is_assigned_to_users_organization?(user)
      return [
        Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h,
        Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h,
        Constants.TASK_ACTIONS.MARK_COMPLETE.to_h,
        Constants.TASK_ACTIONS.CANCEL_TASK.to_h
      ]
    end

    []
  end
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/MethodLength

  # Use the existence of an organization-level task to prevent duplicates since there should only ever be one org-level
  # task active at a time for a single appeal.
  def verify_org_task_unique
    # do not verify for split appeal process
    return if appeal.appeal_split_process == true
    return if !open?

    if appeal.tasks.open.where(
      type: type,
      assigned_to: assigned_to,
      parent: parent
    ).any? && assigned_to.is_a?(Organization)
      fail(
        Caseflow::Error::DuplicateOrgTask,
        docket_number: appeal.docket_number,
        task_type: self.class.name,
        assignee_type: assigned_to.class.name
      )
    end
  end

  def label
    self.class.label
  end

  def default_instructions
    []
  end

  # includes on_hold
  def open?
    self.class.open_statuses.include?(status)
  end

  def closed?
    self.class.closed_statuses.include?(status)
  end

  def open_with_no_children?
    open? && children.empty?
  end

  # When a status is "active" we expect properties of the task to change
  # When a task is not "active" we expect that properties of the task will not change
  # on_hold is not included
  def active?
    self.class.active_statuses.include?(status)
  end

  # available_actions() returns an array of options selected by
  # the subclass from TASK_ACTIONS that looks something like:
  # [ { "label": "Assign to person", "value": "modal/assign_to_person", "func": "assignable_users" }, ... ]
  def available_actions_unwrapper(user)
    actions_available?(user) ? available_actions(user).map { |action| build_action_hash(action, user) } : []
  end

  def build_action_hash(action, user)
    TaskActionHelper.build_hash(action, self, user)
  end

  # A wrapper around actions_allowable that also disallows doing actions to on_hold tasks.
  def actions_available?(user)
    return false if status == Constants.TASK_STATUSES.on_hold && !on_timed_hold?

    actions_allowable?(user)
  end

  def actions_allowable?(user)
    return false if !open?

    # Users who are assigned an open subtask of an organization don't have actions on the organizational task.
    return false if assigned_to.is_a?(Organization) && children.open.any? { |child| child.assigned_to == user }

    true
  end

  def assigned_by_display_name
    if assigned_by.try(:full_name)
      return assigned_by.full_name.split(" ")
    end

    ["", ""]
  end

  def post_dispatch_task?
    dispatch_task = appeal.tasks.completed.find_by(type: [BvaDispatchTask.name, QualityReviewTask.name])

    return false unless dispatch_task

    created_at > dispatch_task.closed_at
  end

  def children_attorney_tasks
    children.where(type: AttorneyTask.name)
  end

  def on_timed_hold?
    !active_child_timed_hold_task.nil? || type == PostSendInitialNotificationLetterHoldingTask.name
  end

  def active_child_timed_hold_task
    children.open.find { |task| task.type == TimedHoldTask.name }
  end

  def cancel_timed_hold
    active_child_timed_hold_task&.update!(status: Constants.TASK_STATUSES.cancelled)
  end

  def calculated_placed_on_hold_at
    active_child_timed_hold_task&.timer_start_time || placed_on_hold_at
  end

  def calculated_on_hold_duration
    timed_hold_task = active_child_timed_hold_task
    (timed_hold_task&.timer_end_time&.to_date &.- timed_hold_task&.timer_start_time&.to_date)&.to_i
  end

  def calculated_last_change_duration
    (Time.zone.today - updated_at&.to_date)&.to_i
  end

  def calculated_duration_from_board_intake
    (Time.zone.today - created_at&.to_date)&.to_i
  end

  def update_task_type(params)
    multi_transaction do
      new_branch_task = first_ancestor_of_type.create_twin_of_type(params)
      new_child_task = new_branch_task.last_descendant_of_type

      if assigned_to.is_a?(User) && new_child_task.assigned_to.is_a?(User) &&
         parent.assigned_to_same_org?(new_child_task.parent)
        new_child_task.update!(assigned_to: assigned_to)
      end

      # Move children from the old childmost task to the new childmost task
      children.open.each { |child| child.update!(parent_id: last_descendant_of_type.id) }
      # Cancel all tasks under the old task type branch
      first_ancestor_of_type.cancel_descendants

      [first_ancestor_of_type.descendants, new_branch_task.first_ancestor_of_type.descendants].flatten
    end
  end

  def unscoped_assigned_to
    return Organization.unscoped.find(assigned_to_id) if assigned_to_type == "Organization"

    assigned_to
  end

  def assigned_to_same_org?(task_to_check)
    assigned_to.is_a?(Organization) && assigned_to.eql?(task_to_check.assigned_to)
  end

  def first_ancestor_of_type
    same_task_type?(parent) ? parent.first_ancestor_of_type : self
  end

  def last_descendant_of_type
    child_of_task_type = children.open.detect { |child| same_task_type?(child) }
    child_of_task_type&.last_descendant_of_type || self
  end

  def same_task_type?(task_to_check)
    type.eql?(task_to_check&.type)
  end

  def cancel_descendants(instructions: [])
    descendants.select(&:open?).each do |desc|
      desc.update_with_instructions(status: Constants.TASK_STATUSES.cancelled, instructions: instructions)
    end
  end

  def create_twin_of_type(_params)
    fail Caseflow::Error::ActionForbiddenError, message: "Cannot change type of this task"
  end

  def update_from_params(params, current_user)
    verify_user_can_update!(current_user)
    return reassign(params[:reassign], current_user) if params[:reassign]

    update_with_instructions(params)

    [self]
  end

  def update_with_instructions(params)
    params[:instructions] = flattened_instructions(params)
    update!(params)

    # if completing a letter task, update completed_by to current user.
    if completed? && is_a?(LetterTask) && completed_by.nil?
      update!(completed_by: RequestStore[:current_user])
    end
  end

  def flattened_instructions(params)
    [instructions, params.dig(:instructions).presence].flatten.compact
  end

  def append_instruction(instruction)
    update!(instructions: flattened_instructions(instructions: instruction))
  end

  def hide_from_queue_table_view
    self.class.hide_from_queue_table_view
  end

  def hide_from_case_timeline
    !child_user_tasks_of_same_type.empty?
  end

  def hide_from_task_snapshot
    # We want to hide org tasks if there is an open user task of same type
    # However, if user task has been cancelled, show the org task so that an org admin can assign to another user
    child_user_tasks_of_same_type.any? { |child_task| !child_task.cancelled? }
  end

  def legacy?
    appeal_type == LegacyAppeal.name
  end

  def ama?
    appeal_type == Appeal.name
  end

  def days_waiting
    (Time.zone.today - assigned_at.to_date).to_i if assigned_at
  end

  def latest_attorney_case_review
    # Should be the same as calling: appeal.latest_attorney_case_review
    @latest_attorney_case_review ||= AttorneyCaseReview.where(appeal: appeal).order(:created_at).last
  end

  def prepared_by_display_name
    return nil unless latest_attorney_case_review

    if latest_attorney_case_review.attorney.try(:full_name)
      return latest_attorney_case_review.attorney.full_name.split(" ")
    end

    ["", ""]
  end

  def when_child_task_completed(child_task)
    update_status_if_children_tasks_are_closed(child_task)
  end

  def when_child_task_created(child_task)
    cancel_timed_hold unless child_task.is_a?(TimedHoldTask)

    put_on_hold_due_to_new_child_task
  end

  def put_on_hold_due_to_new_child_task
    if !on_hold?
      Raven.capture_message("Closed task #{id} re-opened because child task created") if !open?
      update!(status: :on_hold)
    end
  end

  # N.B. that this does not check permissions, only assignee
  # Use task_is_assigned_to_users_organization? if that is needed.
  def task_is_assigned_to_organization?(org)
    assigned_to.is_a?(Organization) && assigned_to == org
  end

  def task_is_assigned_to_users_organization?(user)
    assigned_to.is_a?(Organization) && assigned_to.user_has_access?(user)
  end

  def task_is_assigned_to_user_within_organization?(user)
    parent&.assigned_to.is_a?(Organization) &&
      assigned_to.is_a?(User) &&
      parent.assigned_to.user_has_access?(user)
  end

  def assigned_to_vso_user?
    assigned_to.is_a?(User) && assigned_to.vso_employee?
  end

  def can_be_updated_by_user?(user)
    available_actions_unwrapper(user).any?
  end

  def verify_user_can_update!(user)
    unless can_be_updated_by_user?(user)
      fail Caseflow::Error::ActionForbiddenError, message: "Current user cannot access this task"
    end
  end

  # rubocop:disable Metrics/AbcSize
  def reassign(reassign_params, current_user)
    # We do not validate the number of tasks in this scenario because when a
    # task is reassigned, more than one open task of the same type must exist during the reassignment.
    @skip_check_for_only_open_task_of_type = true
    replacement = dup.tap do |task|
      begin
        ActiveRecord::Base.transaction do
          if !reassign_params[:previous].nil?
            reassign_params[:previous][:new_judge] = self.class.child_task_assignee(parent, reassign_params).css_id
          end
          task.assigned_by_id = self.class.child_assigned_by_id(parent, current_user)
          task.assigned_to = self.class.child_task_assignee(parent, reassign_params)
          task.instructions = [reassign_params[:instructions]]
          task.status = Constants.TASK_STATUSES.assigned
          task.previous ? (task.previous << reassign_params[:previous]) : (task.previous = [reassign_params[:previous]])
          task.save!
        end
      ensure
        @skip_check_for_only_open_task_of_type = nil
      end
    end

    # Preserve the open children and status of the old task
    children.select(&:stays_with_reassigned_parent?).each { |child| child.update!(parent_id: replacement.id) }
    replacement.update!(status: status)
    update_with_instructions(status: Constants.TASK_STATUSES.cancelled, instructions: reassign_params[:instructions])

    appeal.overtime = false if appeal.overtime? && reassign_clears_overtime?

    [replacement, self, replacement.children].flatten
  end
  # rubocop:enable Metrics/AbcSize

  def can_move_on_docket_switch?
    return false unless open_with_no_children?
    return false if type.include?("DocketSwitch")
    return false if %w[RootTask DistributionTask HearingTask EvidenceSubmissionWindowTask].include?(type)
    return false if ancestor_task_of_type(HearingTask).present?
    return false if ancestor_task_of_type(EvidenceSubmissionWindowTask).present?

    true
  end

  def post_distribution?
    [JudgeAssignTask, JudgeDecisionReviewTask].any? do |task_type|
      type == task_type.to_s || ancestor_task_of_type(task_type).present?
    end
  end

  ATTRIBUTES_EXCLUDED_FROM_TASK_COPY = %w[id created_at updated_at appeal_id parent_id].freeze

  # This method is for copying a task and its ancestors to a new appeal stream
  def copy_with_ancestors_to_stream(new_appeal_stream, extra_excluded_attributes: [], new_attributes: {})
    return unless parent

    new_task_attributes = attributes
      .except(*ATTRIBUTES_EXCLUDED_FROM_TASK_COPY, *extra_excluded_attributes)
      .merge(new_attributes)
    new_task_attributes["appeal_id"] = new_appeal_stream.id

    # This method recurses until the parent is nil or a task of its type is already present on the new stream
    # We reload the new_appeal_stream to ensure we are always working off an updated snapshot of task tree
    existing_new_parent = new_appeal_stream.reload.tasks.find { |task| task.type == parent.type }
    new_parent = existing_new_parent || parent.copy_with_ancestors_to_stream(new_appeal_stream)

    # Do not copy orphaned branches
    return unless new_parent

    new_task_attributes["parent_id"] = new_parent.id

    # Skip validation since these are not new tasks (and don't need to have a status of assigned, for example)
    new_stream_task = self.class.new(new_task_attributes)
    # Note that if we also want to skip 'before_create', 'after_create', 'before_save', and 'after_save' callbacks
    # (such as in TimedHoldTask) or even things like 'validate :status_is_valid_on_create on: :create',
    # see SanitizedJsonImporter::SkipCallbacks for a possible solution.
    new_stream_task.save(validate: false)

    new_stream_task
  end

  def root_task(task_id = nil)
    task_id = id if task_id.nil?
    return parent.root_task(task_id) if parent
    return self if type == RootTask.name

    fail Caseflow::Error::NoRootTask, task_id: task_id
  end

  def descendants
    [self, children.map(&:descendants)].flatten
  end

  def cancel_task_and_child_subtasks
    # Cancel all descendants at the same time to avoid after_update hooks marking some tasks as completed.
    # it would be better if we could allow the callbacks to happen sanely
    descendant_ids = descendants.pluck(:id)

    # by avoiding callbacks, we aren't saving PaperTrail versions
    # Manually save the state before and after.
    tasks = Task.open.where(id: descendant_ids)
    transaction do
      tasks.each { |task| task.paper_trail.save_with_version }
      tasks.update_all(
        status: Constants.TASK_STATUSES.cancelled,
        cancelled_by_id: RequestStore[:current_user]&.id,
        closed_at: Time.zone.now
      )
      tasks.each { |task| task.reload.paper_trail.save_with_version }
    end
  end

  def ancestor_task_of_type(task_type)
    return nil unless parent

    parent.is_a?(task_type) ? parent : parent.ancestor_task_of_type(task_type)
  end

  def previous_task
    nil
  end

  # :reek:FeatureEnvy
  def version_summary
    versions.map do |version|
      {
        who: [User.find_by_id(version.whodunnit)].compact
          .map { |user| "#{user.css_id} (#{user.id}, #{user.full_name})" }.first,
        when: version.created_at,
        changeset: version.changeset
      }
    end
  end

  def timeline_title
    "#{type} completed"
  end

  def serializer_class
    ::WorkQueue::TaskSerializer
  end

  def assigned_to_label
    assigned_to.is_a?(Organization) ? assigned_to.name : assigned_to.css_id
  end

  def child_must_have_active_assignee?
    true
  end

  def stays_with_reassigned_parent?
    open?
  end

  def reassign_clears_overtime?
    false
  end

  def serialize_for_cancellation
    assignee_display_name = if assigned_to.is_a?(Organization)
                              assigned_to.name
                            else
                              "#{assigned_to.full_name.titlecase} (#{assigned_to.css_id})"
                            end

    {
      id: id,
      assigned_to_email: assigned_to.is_a?(Organization) ? assigned_to.admins.first&.email : assigned_to.email,
      assigned_to_name: assignee_display_name,
      type: type
    }
  end

  # currently only defined by ScheduleHearingTask and AssignHearingDispositionTask for virtual hearing related updates
  def alerts
    @alerts ||= []
  end

  # Purpose: This method is triggered by callback 'after_update'.
  # This method calls a variety of abstract private methods that are prepended in app/models/prepend/va_notifiy.
  # These private methods will update an appeal's state within the 'Appeal State' table when certain tracked task
  # types have their statuses updated to either 'cancelled' or 'completed'.
  #
  # Params: NONE
  #
  # Response: The Appeal State record correlated to the current task's appeal will be updated.
  def update_appeal_state_on_status_change
    update_appeal_state_when_ihp_cancelled
    update_appeal_state_when_ihp_completed
    update_appeal_state_when_privacy_act_cancelled
    update_appeal_state_when_privacy_act_complete
    update_appeal_state_when_appeal_cancelled
  end

  # Purpose: This method is triggered by callback 'after_create'.  This method calls a variety of abstract private
  # methods that are prepended in app/models/prepend/va_notifiy.  These private methods will update an appeal's state
  # within the 'Appeal State' table when certain tracked tasks are created.
  #
  # Params: NONE
  #
  # Response: The Appeal State record correlated to the current task's appeal will be updated.
  def update_appeal_state_on_task_creation
    update_appeal_state_when_privacy_act_created
    update_appeal_state_when_appeal_docketed
    update_appeal_state_when_ihp_created
  end

  private

  def create_and_auto_assign_child_task(options = {})
    dup.tap do |child_task|
      child_task.assigned_to = assigned_to.next_assignee(**options)
      child_task.parent = self
      child_task.save!
    end
  end

  def automatically_assign_org_task?
    assigned_to.is_a?(Organization) && assigned_to.automatically_assign_to_member?
  end

  def update_parent_status
    parent.when_child_task_completed(self)
  end

  def tell_parent_task_child_task_created
    parent&.when_child_task_created(self)
  end

  def update_children_status_after_closed
    active_child_timed_hold_task&.update!(status: Constants.TASK_STATUSES.cancelled)
  end

  def cancel_task_timers
    task_timers.processable.each do |task_timer|
      task_timer.update!(canceled_at: Time.zone.now)
    end
  end

  def task_just_closed?
    saved_change_to_attribute?("status") && !open?
  end

  def task_will_be_cancelled?
    status_change_to_be_saved&.last == Constants.TASK_STATUSES.cancelled
  end

  def task_just_closed_and_has_parent?
    task_just_closed? && parent
  end

  def child_user_tasks_of_same_type
    return [] unless assigned_to_type == "Organization"

    descendants.select do |child_task|
      child_task.assigned_to_type == "User" && type == child_task.type
    end
  end

  def update_status_if_children_tasks_are_closed(child_task)
    if children.any? && children.open.empty? && on_hold?
      if assigned_to.is_a?(Organization) && cascade_closure_from_child_task?(child_task)
        return all_children_cancelled_or_completed
      end

      update_task_if_children_tasks_are_completed
    end
  end

  # If an Education pre-docket RPO task is completed and sent to BVA Intake
  # then the parent Education EMO task should also be completed.
  def update_task_if_children_tasks_are_completed
    if type == EducationDocumentSearchTask.name && children.last.completed?
      update!(status: Constants.TASK_STATUSES.completed)
    else
      update!(status: Constants.TASK_STATUSES.assigned)
    end
  end

  def all_children_cancelled_or_completed
    if all_children_cancelled?
      update!(status: Constants.TASK_STATUSES.cancelled)
    else
      update!(status: Constants.TASK_STATUSES.completed)
    end
  end

  def all_children_cancelled?
    children.pluck(:status).uniq == [Constants.TASK_STATUSES.cancelled]
  end

  def all_children_completed?
    children.pluck(:status).uniq == [Constants.TASK_STATUSES.completed]
  end

  def cascade_closure_from_child_task?(child_task)
    return if is_a?(AssessDocumentationTask)

    type == child_task&.type
  end

  def set_assigned_at
    self.assigned_at = created_at unless assigned_at
  end

  def set_cancelled_by_id
    self.cancelled_by_id = RequestStore[:current_user].id if RequestStore[:current_user]&.id
  end

  STATUS_TIMESTAMPS = {
    assigned: :assigned_at,
    in_progress: :started_at,
    on_hold: :placed_on_hold_at,
    completed: :closed_at,
    cancelled: :closed_at
  }.freeze

  def set_timestamp
    return unless will_save_change_to_attribute?(:status)

    timestamp_to_update = STATUS_TIMESTAMPS[status_change_to_be_saved&.last&.to_sym]
    return if will_save_change_to_attribute?(timestamp_to_update)

    self[timestamp_to_update] = Time.zone.now

    nullify_closed_at_if_reopened if closed_at.present?
  end

  def nullify_closed_at_if_reopened
    return unless self.class.open_statuses.include?(status_change_to_be_saved&.last)

    self.closed_at = nil
  end

  def status_is_valid_on_create
    if status != Constants.TASK_STATUSES.assigned
      fail Caseflow::Error::InvalidStatusOnTaskCreate, task_type: type
    end

    true
  end

  def assignee_status_is_valid_on_create
    if parent&.child_must_have_active_assignee? && assigned_to.is_a?(User) && !assigned_to.active?
      fail Caseflow::Error::InvalidAssigneeStatusOnTaskCreate, assignee: assigned_to
    end

    true
  end

  def only_open_task_of_type
    if appeal.reload.tasks.open.of_type(type).any?
      fail Caseflow::Error::MultipleOpenTasksOfSameTypeError, task_type: type
    end
  end

  def parent_can_have_children
    if parent&.class&.cannot_have_children
      fail Caseflow::Error::InvalidParentTask, message: "Child tasks cannot be created for #{parent.type}s"
    end

    true
  end
end
# rubocop:enable Metrics/ClassLength
