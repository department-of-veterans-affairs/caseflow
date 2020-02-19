# frozen_string_literal: true

##
# Base model for all tasks in generic organizational task queues in Caseflow
# Tasks represent work to be done by judges, attorneys, VSOs, and anyone else who touches a Veteran's appeal.
# Supports common actions like:
#   - marking tasks complete
#   - assigning a task to a team
#   - assigning a task to an individual

# rubocop:disable Metrics/ClassLength
class Task < ApplicationRecord
  has_paper_trail on: [:update, :destroy]
  acts_as_tree

  include PrintsTaskTree

  belongs_to :assigned_to, polymorphic: true
  belongs_to :assigned_by, class_name: "User"
  belongs_to :appeal, polymorphic: true
  has_many :attorney_case_reviews, dependent: :destroy
  has_many :task_timers, dependent: :destroy

  validates :assigned_to, :appeal, :type, :status, presence: true
  validate :status_is_valid_on_create, on: :create
  validate :assignee_status_is_valid_on_create, on: :create
  validate :parent_can_have_children

  before_create :set_assigned_at
  before_create :verify_org_task_unique

  after_create :create_and_auto_assign_child_task, if: :automatically_assign_org_task?
  after_create :tell_parent_task_child_task_created

  before_save :set_timestamp
  after_update :update_parent_status, if: :task_just_closed_and_has_parent?
  after_update :update_children_status_after_closed, if: :task_just_closed?
  after_update :cancel_task_timers, if: :task_just_closed?

  enum status: {
    Constants.TASK_STATUSES.assigned.to_sym => Constants.TASK_STATUSES.assigned,
    Constants.TASK_STATUSES.in_progress.to_sym => Constants.TASK_STATUSES.in_progress,
    Constants.TASK_STATUSES.on_hold.to_sym => Constants.TASK_STATUSES.on_hold,
    Constants.TASK_STATUSES.completed.to_sym => Constants.TASK_STATUSES.completed,
    Constants.TASK_STATUSES.cancelled.to_sym => Constants.TASK_STATUSES.cancelled
  }

  # This suppresses a warning about the :open scope overwriting the Kernel#open method
  # https://ruby-doc.org/core-2.6.3/Kernel.html#method-i-open
  class << self; undef_method :open; end

  scope :active, -> { where(status: active_statuses) }

  scope :open, -> { where(status: open_statuses) }

  scope :closed, -> { where(status: closed_statuses) }

  scope :not_cancelled, -> { where.not(status: Constants.TASK_STATUSES.cancelled) }

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

  ############################################################################################
  ## class methods
  class << self
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

    def recently_closed
      closed.where(closed_at: (Time.zone.now - 1.week)..Time.zone.now)
    end

    def incomplete_or_recently_closed
      open.or(recently_closed)
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
      parent_task = Task.find(params[:parent_id])
      fail Caseflow::Error::ChildTaskAssignedToSameUser if parent_task.assigned_to_id == params[:assigned_to_id] &&
                                                           parent_task.assigned_to_type == params[:assigned_to_type]

      verify_user_can_create!(user, parent_task)

      params = modify_params_for_create(params)
      child = create_child_task(parent_task, user, params)
      parent_task.update!(status: params[:status]) if params[:status]
      child
    end

    def create_child_task(parent, current_user, params)
      Task.create!(
        type: name,
        appeal: parent.appeal,
        assigned_by_id: child_assigned_by_id(parent, current_user),
        parent_id: parent.id,
        assigned_to: params[:assigned_to] || child_task_assignee(parent, params),
        instructions: params[:instructions]
      )
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
    return if !open?

    if appeal.tasks.open.where(
      type: type,
      assigned_to: assigned_to,
      parent: parent
    ).any? && assigned_to.is_a?(Organization)
      fail(
        Caseflow::Error::DuplicateOrgTask,
        appeal_id: appeal.id,
        task_type: self.class.name,
        assignee_type: assigned_to.class.name,
        parent_id: parent&.id
      )
    end
  end

  def available_hearing_user_actions(user)
    available_hearing_admin_actions(user) | available_hearing_mgmt_actions(user)
  end

  def create_change_hearing_disposition_task(instructions = nil)
    hearing_task = ancestor_task_of_type(HearingTask)

    if hearing_task.blank?
      fail(Caseflow::Error::ActionForbiddenError, message: COPY::REQUEST_HEARING_DISPOSITION_CHANGE_FORBIDDEN_ERROR)
    end

    hearing_task.create_change_hearing_disposition_task(instructions)
  end

  def most_recent_closed_hearing_task_on_appeal
    appeal.tasks.closed.order(closed_at: :desc).where(type: HearingTask.name).last
  end

  def label
    self.class.label
  end

  def default_instructions
    []
  end

  # When a status is "active" we expect properties of the task to change. When a task is not "active" we expect that
  # properties of the task will not change.
  def open?
    !self.class.closed_statuses.include?(status)
  end

  def open_with_no_children?
    open? && children.empty?
  end

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

    # Users who are assigned a subtask of an organization don't have actions on the organizational task.
    return false if assigned_to.is_a?(Organization) && children.any? { |child| child.assigned_to == user }

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
    !active_child_timed_hold_task.nil?
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

  def cancel_descendants
    descendants.each { |desc| desc.update!(status: Constants.TASK_STATUSES.cancelled) }
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
  end

  def flattened_instructions(params)
    [instructions, params.dig(:instructions).presence].flatten.compact
  end

  def hide_from_queue_table_view
    self.class.hide_from_queue_table_view
  end

  def duplicate_org_task
    assigned_to.is_a?(Organization) && children.any? do |child_task|
      User.name == child_task.assigned_to_type && type == child_task.type
    end
  end

  def hide_from_case_timeline
    duplicate_org_task
  end

  def hide_from_task_snapshot
    duplicate_org_task
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
    return @latest_attorney_case_review if defined?(@latest_attorney_case_review)

    @latest_attorney_case_review = AttorneyCaseReview
      .where(task_id: Task.where(appeal: appeal)
      .pluck(:id))
      .order(:created_at).last
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

    if !on_hold?
      Raven.capture_message("Closed task #{id} re-opened because child task created") if !open?
      update!(status: :on_hold)
    end
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

  def reassign(reassign_params, current_user)
    sibling = dup.tap do |task|
      task.assigned_by_id = self.class.child_assigned_by_id(parent, current_user)
      task.assigned_to = self.class.child_task_assignee(parent, reassign_params)
      task.instructions = flattened_instructions(reassign_params)
      task.status = Constants.TASK_STATUSES.assigned
      task.save!
    end

    # Preserve the open children and status of the old task
    children.select(&:stays_with_reassigned_parent?).each { |child| child.update!(parent_id: sibling.id) }
    sibling.update!(status: status)

    update_with_instructions(status: Constants.TASK_STATUSES.cancelled, instructions: reassign_params[:instructions])

    [sibling, self, sibling.children].flatten
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

  def ancestor_task_of_type(task_type)
    return nil unless parent

    parent.is_a?(task_type) ? parent : parent.ancestor_task_of_type(task_type)
  end

  def previous_task
    nil
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
        closed_at: Time.zone.now
      )
      tasks.each { |task| task.reload.paper_trail.save_with_version }
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

  private

  def available_hearing_admin_actions(user)
    return [] unless HearingAdmin.singleton.user_has_access?(user)

    hearing_task = ancestor_task_of_type(HearingTask)
    return [] unless hearing_task&.open? && hearing_task&.disposition_task&.present?

    [
      Constants.TASK_ACTIONS.CREATE_CHANGE_HEARING_DISPOSITION_TASK.to_h
    ]
  end

  def available_hearing_mgmt_actions(user)
    return [] unless type == ScheduleHearingTask.name
    return [] unless HearingsManagement.singleton.user_has_access?(user)

    return [] if most_recent_closed_hearing_task_on_appeal&.hearing&.disposition.blank?

    [
      Constants.TASK_ACTIONS.CREATE_CHANGE_PREVIOUS_HEARING_DISPOSITION_TASK.to_h
    ]
  end

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

  def task_just_closed_and_has_parent?
    task_just_closed? && parent
  end

  def update_status_if_children_tasks_are_closed(child_task)
    if children.any? && children.open.empty? && on_hold?
      if assigned_to.is_a?(Organization) && cascade_closure_from_child_task?(child_task)
        return all_children_cancelled_or_completed
      end

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

  def cascade_closure_from_child_task?(child_task)
    type == child_task&.type
  end

  def set_assigned_at
    self.assigned_at = created_at unless assigned_at
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

  def parent_can_have_children
    if parent&.class&.cannot_have_children
      fail Caseflow::Error::InvalidParentTask, message: "Child tasks cannot be created for #{parent.type}s"
    end

    true
  end
end
# rubocop:enable Metrics/ClassLength
