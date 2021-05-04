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
  belongs_to :appeal, polymorphic: true
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

  before_save :set_timestamp

  before_update :set_cancelled_by_id, if: :task_will_be_cancelled?
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

  enum cancellation_reason: {
    Constants.TASK_CANCELLATION_REASONS.poa_change.to_sym => Constants.TASK_CANCELLATION_REASONS.poa_change
  }

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
      fail Caseflow::Error::ChildTaskAssignedToSameUser if parent_of_same_type_has_same_assignee(parent_task, params)

      verify_user_can_create!(user, parent_task)

      params = modify_params_for_create(params)
      child = create_child_task(parent_task, user, params)
      parent_task.update!(status: params[:status]) if params[:status]
      child
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
        instructions: params[:instructions]
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
  end

  def flattened_instructions(params)
    [instructions, params.dig(:instructions).presence].flatten.compact
  end

  def hide_from_queue_table_view
    self.class.hide_from_queue_table_view
  end

  def duplicate_org_task
    assigned_to.is_a?(Organization) && descendants.any? do |child_task|
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

    put_on_hold_due_to_new_child_task
  end

  def put_on_hold_due_to_new_child_task
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

  # rubocop:disable Metrics/AbcSize
  def reassign(reassign_params, current_user)
    Thread.current.thread_variable_set(:skip_duplicate_validation, true)
    replacement = dup.tap do |task|
      begin
        ActiveRecord::Base.transaction do
          task.assigned_by_id = self.class.child_assigned_by_id(parent, current_user)
          task.assigned_to = self.class.child_task_assignee(parent, reassign_params)
          task.instructions = flattened_instructions(reassign_params)
          task.status = Constants.TASK_STATUSES.assigned

          task.save!
        end
      # The ensure block guarantees that the thread-local variable skip_duplicate_validation
      # does not leak outside of this method
      ensure
        Thread.current[:skip_duplicate_validation] = nil
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

  # This method is for copying a task and its ancestors to a new appeal stream
  def copy_with_ancestors_to_stream(new_appeal_stream)
    return unless parent

    new_task_attributes = attributes.reject { |attr| %w[id created_at updated_at appeal_id parent_id].include?(attr) }
    new_task_attributes["appeal_id"] = new_appeal_stream.id

    # This method recurses until the parent is nil or a task of its type is already present on the new stream
    existing_new_parent = new_appeal_stream.tasks.find { |task| task.type == parent.type }
    new_parent = existing_new_parent || parent.copy_with_ancestors_to_stream(new_appeal_stream)

    # Do not copy orphaned branches
    return unless new_parent

    new_task_attributes["parent_id"] = new_parent.id

    # Skip validation since these are not new tasks (and don't need to have a status of assigned, for example)
    new_stream_task = self.class.new(new_task_attributes)
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
        cancelled_by_id: RequestStore[:current_user]&.id,
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

  def no_multiples_of_noncancelled_task
    if Thread.current[:skip_duplicate_validation]
      return
    end

    tasks = appeal.reload.tasks
    target_tasks = tasks.open.of_type(type)
    if target_tasks.length >= 1
      errors.add(:type, COPY::INVALID_MULTIPLE_TASKS)
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
