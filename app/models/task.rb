class Task < ApplicationRecord
  acts_as_tree

  belongs_to :assigned_to, polymorphic: true
  belongs_to :assigned_by, class_name: User.name
  belongs_to :appeal, polymorphic: true
  has_many :attorney_case_reviews

  validates :assigned_to, :appeal, :type, :status, presence: true

  before_create :set_assigned_at
  after_create :create_and_auto_assign_child_task, if: :automatically_assign_org_task?
  after_create :put_parent_on_hold

  before_update :set_timestamps
  after_update :update_parent_status, if: :status_changed_to_completed_and_has_parent?
  after_update :update_children_status, if: :status_changed_to_completed?

  enum status: {
    Constants.TASK_STATUSES.assigned.to_sym => Constants.TASK_STATUSES.assigned,
    Constants.TASK_STATUSES.in_progress.to_sym => Constants.TASK_STATUSES.in_progress,
    Constants.TASK_STATUSES.on_hold.to_sym => Constants.TASK_STATUSES.on_hold,
    Constants.TASK_STATUSES.completed.to_sym => Constants.TASK_STATUSES.completed,
    Constants.TASK_STATUSES.cancelled.to_sym => Constants.TASK_STATUSES.cancelled
  }

  scope :active, -> { where.not(status: inactive_statuses) }

  scope :inactive, -> { where(status: inactive_statuses) }

  def available_actions(_user)
    []
  end

  def label
    action
  end

  def self.inactive_statuses
    [Constants.TASK_STATUSES.completed, Constants.TASK_STATUSES.cancelled]
  end

  # When a status is "active" we expect properties of the task to change. When a task is not "active" we expect that
  # properties of the task will not change.
  def active?
    !self.class.inactive_statuses.include?(status)
  end

  # available_actions() returns an array of options from selected by the subclass
  # from TASK_ACTIONS that looks something like:
  # [ { "label": "Assign to person", "value": "modal/assign_to_person", "func": "assignable_users" }, ... ]
  def available_actions_unwrapper(user)
    actions = actions_available?(user) ? available_actions(user).map { |action| build_action_hash(action, user) } : []

    # Make sure each task action has a unique URL so we can determine which action we are selecting on the frontend.
    if actions.length > actions.pluck(:value).uniq.length
      fail Caseflow::Error::DuplicateTaskActionPaths, task_id: id, user_id: user.id, labels: actions.pluck(:label)
    end

    actions
  end

  def build_action_hash(action, user)
    { label: action[:label], value: action[:value], data: action[:func] ? send(action[:func], user) : nil }
  end

  # A wrapper around actions_allowable that also disallows doing actions to on_hold tasks.
  def actions_available?(user)
    return false if status == Constants.TASK_STATUSES.on_hold

    actions_allowable?(user)
  end

  def actions_allowable?(user)
    return false if !active?

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

  def self.recently_closed
    inactive.where(closed_at: (Time.zone.now - 2.weeks)..Time.zone.now)
  end

  def self.incomplete_or_recently_closed
    active.or(recently_closed)
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

  def update_from_params(params, current_user)
    verify_user_can_update!(current_user)

    return reassign(params[:reassign], current_user) if params[:reassign]

    params["instructions"] = [instructions, params["instructions"]].flatten if params.key?("instructions")
    update!(params)

    [self]
  end

  def hide_from_queue_table_view
    false
  end

  def hide_from_case_timeline
    false
  end

  def hide_from_task_snapshot
    false
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
    AttorneyCaseReview.where(task_id: Task.where(appeal: appeal).pluck(:id)).order(:created_at).last
  end

  def prepared_by_display_name
    return nil unless latest_attorney_case_review

    if latest_attorney_case_review.attorney.try(:full_name)
      return latest_attorney_case_review.attorney.full_name.split(" ")
    end

    ["", ""]
  end

  def when_child_task_completed
    update_status_if_children_tasks_are_complete
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

    update!(status: Constants.TASK_STATUSES.completed)

    children.active.each { |t| t.update!(parent_id: sibling.id) }

    [sibling, self, sibling.children].flatten
  end

  def self.child_task_assignee(_parent, params)
    Object.const_get(params[:assigned_to_type]).find(params[:assigned_to_id])
  end

  def self.child_assigned_by_id(parent, current_user)
    return current_user.id if current_user
    return parent.assigned_to_id if parent && parent.assigned_to_type == User.name
  end

  def root_task(task_id = nil)
    task_id = id if task_id.nil?
    return parent.root_task(task_id) if parent
    return self if type == RootTask.name

    fail Caseflow::Error::NoRootTask, task_id: task_id
  end

  def previous_task
    nil
  end

  def assign_to_organization_data(_user = nil)
    organizations = Organization.assignable(self).map do |organization|
      {
        label: organization.name,
        value: organization.id
      }
    end

    {
      selected: nil,
      options: organizations,
      type: GenericTask.name
    }
  end

  def mail_assign_to_organization_data(_user = nil)
    { options: MailTask.subclass_routing_options }
  end

  def assign_to_user_data(user = nil)
    users = if assigned_to.is_a?(Organization)
              assigned_to.users
            elsif parent&.assigned_to.is_a?(Organization)
              parent.assigned_to.users.reject { |u| u == assigned_to }
            else
              []
            end

    {
      selected: user,
      options: users_to_options(users),
      type: type
    }
  end

  def assign_to_judge_data(_user = nil)
    {
      selected: root_task.children.find { |task| task.is_a?(JudgeTask) }&.assigned_to,
      options: users_to_options(Judge.list_all),
      type: JudgeQualityReviewTask.name
    }
  end

  def assign_to_attorney_data(_user = nil)
    {
      selected: nil,
      options: nil,
      type: AttorneyTask.name
    }
  end

  def assign_to_privacy_team_data(_user = nil)
    org = PrivacyTeam.singleton

    {
      selected: org,
      options: [{ label: org.name, value: org.id }],
      type: GenericTask.name
    }
  end

  def assign_to_translation_team_data(_user = nil)
    org = Translation.singleton

    {
      selected: org,
      options: [{ label: org.name, value: org.id }],
      type: TranslationTask.name
    }
  end

  def add_admin_action_data(_user = nil)
    {
      redirect_after: "/queue",
      selected: nil,
      options: Constants::CO_LOCATED_ADMIN_ACTIONS.map do |key, value|
        {
          label: value,
          value: key
        }
      end,
      type: ColocatedTask.name
    }
  end

  def complete_data(_user = nil)
    {
      modal_body: COPY::MARK_TASK_COMPLETE_COPY
    }
  end

  def schedule_veteran_data(_user = nil)
    {
      selected: nil,
      options: nil,
      type: ScheduleHearingTask.name
    }
  end

  def return_to_attorney_data(_user = nil)
    assignee = children.select { |t| t.is_a?(AttorneyTask) }.max_by(&:created_at)&.assigned_to
    attorneys = JudgeTeam.for_judge(assigned_to)&.attorneys || []
    attorneys |= [assignee] if assignee.present?
    {
      selected: assignee,
      options: users_to_options(attorneys),
      type: AttorneyRewriteTask.name
    }
  end

  def timeline_title
    "#{type} completed"
  end

  def timeline_details
    {
      title: timeline_title,
      date: closed_at
    }
  end

  def update_if_hold_expired!
    update!(status: Constants.TASK_STATUSES.in_progress) if on_hold_expired?
  end

  def on_hold_expired?
    return true if on_hold? && placed_on_hold_at && on_hold_duration &&
                   placed_on_hold_at + on_hold_duration.days < Time.zone.now

    false
  end

  def serializer_class
    ::WorkQueue::TaskSerializer
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
    parent.when_child_task_completed
  end

  def update_children_status; end

  def status_changed_to_completed?
    saved_change_to_attribute?("status") && completed?
  end

  def status_changed_to_completed_and_has_parent?
    status_changed_to_completed? && parent
  end

  def users_to_options(users)
    users.map do |user|
      {
        label: user.full_name,
        value: user.id
      }
    end
  end

  def update_status_if_children_tasks_are_complete
    if children.any? && children.select(&:active?).empty?
      return update!(status: Constants.TASK_STATUSES.completed) if assigned_to.is_a?(Organization)
      return update!(status: :assigned) if on_hold?
    end
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
