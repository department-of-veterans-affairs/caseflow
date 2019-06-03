# frozen_string_literal: true

##
# Base model for all tasks in Caseflow.
# Tasks represent work to be done by judges, attorneys, VSOs, and anyone else who touches a Veteran's appeal.

class Task < ApplicationRecord
  acts_as_tree

  belongs_to :assigned_to, polymorphic: true
  belongs_to :assigned_by, class_name: "User"
  belongs_to :appeal, polymorphic: true
  has_many :attorney_case_reviews
  has_many :task_timers, dependent: :destroy

  validates :assigned_to, :appeal, :type, :status, presence: true

  before_create :set_assigned_at
  after_create :create_and_auto_assign_child_task, if: :automatically_assign_org_task?
  after_create :put_parent_on_hold

  before_update :set_timestamps
  after_update :update_parent_status, if: :task_just_closed_and_has_parent?
  after_update :update_children_status_after_closed, if: :task_just_closed?
  after_update :cancel_timed_hold, unless: :task_just_placed_on_hold?

  enum status: {
    Constants.TASK_STATUSES.assigned.to_sym => Constants.TASK_STATUSES.assigned,
    Constants.TASK_STATUSES.in_progress.to_sym => Constants.TASK_STATUSES.in_progress,
    Constants.TASK_STATUSES.on_hold.to_sym => Constants.TASK_STATUSES.on_hold,
    Constants.TASK_STATUSES.completed.to_sym => Constants.TASK_STATUSES.completed,
    Constants.TASK_STATUSES.cancelled.to_sym => Constants.TASK_STATUSES.cancelled
  }

  scope :active, -> { where(status: active_statuses) }

  scope :open, -> { where(status: open_statuses) }

  scope :closed, -> { where(status: closed_statuses) }

  scope :not_tracking, -> { where.not(type: TrackVeteranTask.name) }

  scope :not_decisions_review, lambda {
                                 where.not(
                                   type: DecisionReviewTask.descendants.map(&:name) + ["DecisionReviewTask"]
                                 )
                               }

  def available_actions(_user)
    []
  end

  def label
    self.class.name.titlecase
  end

  def self.closed_statuses
    [Constants.TASK_STATUSES.completed, Constants.TASK_STATUSES.cancelled]
  end

  def self.active_statuses
    [Constants.TASK_STATUSES.assigned, Constants.TASK_STATUSES.in_progress]
  end

  def self.open_statuses
    active_statuses.concat([Constants.TASK_STATUSES.on_hold])
  end

  # When a status is "active" we expect properties of the task to change. When a task is not "active" we expect that
  # properties of the task will not change.
  def open?
    !self.class.closed_statuses.include?(status)
  end

  def open_with_no_children?
    open? && children.empty?
  end

  # available_actions() returns an array of options selected by
  # the subclass from TASK_ACTIONS that looks something like:
  # [ { "label": "Assign to person", "value": "modal/assign_to_person", "func": "assignable_users" }, ... ]
  def available_actions_unwrapper(user)
    actions_available?(user) ? available_actions(user).map { |action| build_action_hash(action, user) } : []
  end

  def appropriate_timed_hold_task_action
    on_timed_hold? ? Constants.TASK_ACTIONS.END_TIMED_HOLD.to_h : Constants.TASK_ACTIONS.PLACE_TIMED_HOLD.to_h
  end

  def build_action_hash(action, user)
    {
      label: action[:label],
      value: action[:value],
      data: action[:func] ? TaskActionRepository.send(action[:func], self, user) : nil
    }
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

  def children_attorney_tasks
    children.where(type: AttorneyTask.name)
  end

  def on_timed_hold?
    !active_child_timed_hold_task.nil?
  end

  def active_child_timed_hold_task
    children.open.find_by(type: TimedHoldTask.name)
  end

  def cancel_timed_hold
    active_child_timed_hold_task&.update!(status: Constants.TASK_STATUSES.cancelled)
  end

  def calculated_placed_on_hold_at
    active_child_timed_hold_task&.timer_start_time || placed_on_hold_at
  end

  def calculated_on_hold_duration
    timed_hold_task = active_child_timed_hold_task
    (timed_hold_task&.timer_end_time&.to_date &.- timed_hold_task&.timer_start_time&.to_date)&.to_i || on_hold_duration
  end

  def self.recently_closed
    closed.where(closed_at: (Time.zone.now - 2.weeks)..Time.zone.now)
  end

  def self.incomplete_or_recently_closed
    open.or(recently_closed)
  end

  def self.create_many_from_params(params_array, current_user)
    params_array.map { |params| create_from_params(params, current_user) }
  end

  def self.create_from_params(params, user)
    parent_task = params[:parent_id] ? Task.find(params[:parent_id]) : nil
    verify_user_can_create!(user, parent_task)
    params = modify_params(params)
    create!(params)
  end

  def self.modify_params(params)
    if params.key?(:instructions) && !params[:instructions].is_a?(Array)
      params[:instructions] = [params[:instructions]]
    end
    params
  end

  def update_task_type(params)
    parents = []

    if parent_is_of_task_type?
      parents = parent.update_task_type(params)
    end

    new_parent = parents.first
    new_task_of_type = auto_created_child_of_task(new_parent)

    if new_task_of_type
      new_task_of_type.update!(assigned_to: assigned_to, status: status)
    else
      new_task_of_type = change_type(params, new_parent)
    end

    update!(status: Constants.TASK_STATUSES.cancelled)
    children.active.each { |child| child.update!(parent_id: new_task_of_type.id) }

    [new_task_of_type, self, new_task_of_type.children, parents].flatten
  end

  def auto_created_child_of_task(task_to_check)
    child_of_parent = task_to_check&.children && task_to_check.children.last
    !eql?(child_of_parent) && child_of_parent
  end

  def parent_is_of_task_type?
    parent.slice(:class, :action, :type).eql? slice(:class, :action, :type)
  end

  def change_type(_params, _new_parent)
    fail Caseflow::Error::ActionForbiddenError, message: "Cannot change type of this task"
  end

  def update_from_params(params, current_user)
    verify_user_can_update!(current_user)

    return reassign(params[:reassign], current_user) if params[:reassign]

    params["instructions"] = flattened_instructions(params)
    update!(params)

    [self]
  end

  def flattened_instructions(params)
    [instructions, params.dig(:instructions).presence].flatten.compact
  end

  def hide_from_queue_table_view
    false
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
    update_status_if_children_tasks_are_complete(child_task)
  end

  def task_is_assigned_to_user_within_organization?(user)
    parent&.assigned_to.is_a?(Organization) &&
      assigned_to.is_a?(User) &&
      parent.assigned_to.user_has_access?(user)
  end

  def can_be_updated_by_user?(user)
    available_actions_unwrapper(user).any?
  end

  def verify_user_can_update!(user)
    unless can_be_updated_by_user?(user)
      fail Caseflow::Error::ActionForbiddenError, message: "Current user cannot access this task"
    end
  end

  def self.verify_user_can_create!(user, parent)
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

  def reassign(reassign_params, current_user)
    sibling = dup.tap do |t|
      t.assigned_by_id = self.class.child_assigned_by_id(parent, current_user)
      t.assigned_to = self.class.child_task_assignee(parent, reassign_params)
      t.instructions = [instructions, reassign_params[:instructions]].flatten
      t.save!
    end

    update!(status: Constants.TASK_STATUSES.cancelled)

    children.open.each { |t| t.update!(parent_id: sibling.id) }

    [sibling, self, sibling.children].flatten
  end

  def self.child_task_assignee(_parent, params)
    Object.const_get(params[:assigned_to_type]).find(params[:assigned_to_id])
  end

  def self.child_assigned_by_id(parent, current_user)
    return current_user.id if current_user
    return parent.assigned_to_id if parent && parent.assigned_to_type == User.name
  end

  def self.most_recently_assigned
    order(:updated_at).last
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
    descendant_ids = descendants.pluck(:id)
    Task.open.where(id: descendant_ids).update_all(
      status: Constants.TASK_STATUSES.cancelled,
      closed_at: Time.zone.now
    )
  end

  def timeline_title
    "#{type} completed"
  end

  def update_if_hold_expired!
    update!(status: Constants.TASK_STATUSES.in_progress) if old_style_hold_expired?
  end

  def old_style_hold_expired?
    !on_timed_hold? && on_hold? && placed_on_hold_at && on_hold_duration &&
      (placed_on_hold_at + on_hold_duration.days < Time.zone.now)
  end

  def serializer_class
    ::WorkQueue::TaskSerializer
  end

  def assigned_to_label
    assigned_to.is_a?(Organization) ? assigned_to.name : assigned_to.css_id
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

  def update_children_status_after_closed; end

  def task_just_closed?
    saved_change_to_attribute?("status") && !open?
  end

  def task_just_closed_and_has_parent?
    task_just_closed? && parent
  end

  def task_just_placed_on_hold?
    saved_change_to_attribute?(:placed_on_hold_at)
  end

  def update_status_if_children_tasks_are_complete(child_task)
    if children.any? && children.open.empty? && on_hold?
      if assigned_to.is_a?(Organization) && cascade_closure_from_child_task?(child_task)
        return update!(status: Constants.TASK_STATUSES.completed)
      end

      update!(status: Constants.TASK_STATUSES.assigned)
    end
  end

  def cascade_closure_from_child_task?(child_task)
    type == child_task&.type
  end

  def set_assigned_at
    self.assigned_at = created_at unless assigned_at
  end

  def put_parent_on_hold
    parent&.update(status: :on_hold)
  end

  def set_timestamps
    if will_save_change_to_status?
      case status_change_to_be_saved&.last&.to_sym
      when :assigned
        self.assigned_at = updated_at
      when :in_progress
        self.started_at = updated_at
      when :on_hold
        self.placed_on_hold_at = updated_at
      when :completed, :cancelled
        self.closed_at = updated_at
      end
    end
  end
end
