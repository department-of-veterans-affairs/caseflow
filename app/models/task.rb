class Task < ApplicationRecord
  acts_as_tree

  belongs_to :assigned_to, polymorphic: true
  belongs_to :assigned_by, class_name: User.name
  belongs_to :appeal, polymorphic: true
  has_many :attorney_case_reviews
  has_many :task_business_payloads

  validates :assigned_to, :appeal, :type, :status, presence: true

  before_create :set_assigned_at_and_update_parent_status
  before_update :set_timestamps

  after_update :update_parent_status

  enum status: {
    Constants.TASK_STATUSES.assigned.to_sym    => Constants.TASK_STATUSES.assigned,
    Constants.TASK_STATUSES.in_progress.to_sym => Constants.TASK_STATUSES.in_progress,
    Constants.TASK_STATUSES.on_hold.to_sym     => Constants.TASK_STATUSES.on_hold,
    Constants.TASK_STATUSES.completed.to_sym   => Constants.TASK_STATUSES.completed
  }

  def available_actions(_user)
    []
  end

  # available_actions() returns an array of options from selected by the subclass
  # from TASK_ACTIONS that looks something like:
  # [ { "label": "Assign to person", "value": "modal/assign_to_person", "func": "assignable_users" }, ... ]
  def available_actions_unwrapper(user)
    return [] if no_actions_available?(user)

    available_actions(user).map do |a|
      { label: a[:label], value: a[:value], data: a[:func] ? send(a[:func]) : nil }
    end
  end

  def no_actions_available?(user)
    return true if [Constants.TASK_STATUSES.on_hold, Constants.TASK_STATUSES.completed].include?(status)

    # Users who are assigned a subtask of an organization don't have actions on the organizational task.
    assigned_to.is_a?(Organization) && children.any? { |child| child.assigned_to == user }
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

  def self.recently_completed
    where(status: Constants.TASK_STATUSES.completed, completed_at: (Time.zone.now - 2.weeks)..Time.zone.now)
  end

  def self.incomplete
    where.not(status: Constants.TASK_STATUSES.completed)
  end

  def self.incomplete_or_recently_completed
    incomplete.or(recently_completed)
  end

  def self.create_many_from_params(params_array, current_user)
    params_array.map { |params| create_from_params(params, current_user) }
  end

  def self.create_from_params(params, user)
    verify_user_can_assign!(user)
    params = modify_params(params)
    create(params)
  end

  def self.modify_params(params)
    if params.key?("instructions") && !params[:instructions].is_a?(Array)
      params["instructions"] = [params["instructions"]]
    end
    params
  end

  def update_from_params(params, _current_user)
    params["instructions"] = [instructions, params["instructions"]].flatten if params.key?("instructions")
    update(params)

    [self]
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

  def colocated_task?
    type == ColocatedTask.name
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

  def mark_as_complete!
    update!(status: :completed)
    parent.when_child_task_completed if parent
  end

  def when_child_task_completed
    update_status_if_children_tasks_are_complete
  end

  def can_be_accessed_by_user?(user)
    if assigned_to == user ||
       assigned_by == user ||
       (parent && parent.assigned_to == user) ||
       Constants::AttorneyJudgeTeams::JUDGES[Rails.current_env].keys.include?(user.css_id)
      return true
    end
    false
  end

  def verify_user_access!(user)
    unless can_be_accessed_by_user?(user)
      fail Caseflow::Error::ActionForbiddenError, message: "Current user cannot access this task"
    end
  end

  def self.verify_user_can_assign!(user)
    unless user.attorney_in_vacols? || user.judge_in_vacols?
      fail Caseflow::Error::ActionForbiddenError, message: "Current user cannot assign this task"
    end
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

  def assign_to_organization_data
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

  def mail_assign_to_organization_data
    assign_to_organization_data.merge(type: MailTask.name)
  end

  def assign_to_user_data
    users = if assigned_to.is_a?(Organization)
              assigned_to.users
            elsif parent && parent.assigned_to.is_a?(Organization)
              parent.assigned_to.users.reject { |u| u == assigned_to }
            else
              []
            end

    {
      selected: nil,
      options: users_to_options(users),
      type: type
    }
  end

  def assign_to_judge_data
    {
      selected: root_task.children.find { |task| task.type == JudgeTask.name }.assigned_to,
      options: users_to_options(Judge.list_all),
      type: JudgeTask.name
    }
  end

  private

  def users_to_options(users)
    users.map do |user|
      {
        label: user.full_name,
        value: user.id
      }
    end
  end

  def update_status_if_children_tasks_are_complete
    if children.any? && children.reject { |t| t.status == Constants.TASK_STATUSES.completed }.empty?
      return mark_as_complete! if assigned_to.is_a?(Organization)
      return update!(status: :assigned) if on_hold?
    end
  end

  def update_parent_status
    parent.when_child_task_completed if saved_change_to_status? && completed? && parent
  end

  def set_assigned_at_and_update_parent_status
    self.assigned_at = created_at
    if ama? && parent
      parent.update(status: :on_hold)
    end
  end

  def set_timestamps
    if will_save_change_to_status?
      self.assigned_at = updated_at if assigned?
      self.started_at = updated_at if in_progress?
      self.placed_on_hold_at = updated_at if on_hold?
      self.completed_at = updated_at if completed?
    end
  end
end
