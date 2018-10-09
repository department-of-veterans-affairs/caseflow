class Task < ApplicationRecord
  acts_as_tree

  belongs_to :assigned_to, polymorphic: true
  belongs_to :assigned_by, class_name: User.name
  belongs_to :appeal, polymorphic: true
  has_many :attorney_case_reviews

  validates :assigned_to, :appeal, :type, :status, presence: true

  before_create :set_assigned_at_and_update_parent_status
  before_update :set_timestamps

  after_update :update_parent_status

  validate :on_hold_duration_is_set, on: :update

  enum status: {
    Constants.TASK_STATUSES.assigned.to_sym    => Constants.TASK_STATUSES.assigned,
    Constants.TASK_STATUSES.in_progress.to_sym => Constants.TASK_STATUSES.in_progress,
    Constants.TASK_STATUSES.on_hold.to_sym     => Constants.TASK_STATUSES.on_hold,
    Constants.TASK_STATUSES.completed.to_sym   => Constants.TASK_STATUSES.completed
  }

  def allowed_actions(_user)
    []
  end

  def assigned_by_display_name
    if assigned_by.try(:full_name)
      return assigned_by.full_name.split(" ")
    end

    ["", ""]
  end

  def children_attorney_tasks
    children.where(type:  AttorneyTask.name)
  end

  def self.create_from_params(params, current_user)
    verify_user_can_assign(current_user)
    params = params.each { |p| p["instructions"] = [p["instructions"]] if p.key?("instructions") }
    create(params)
  end

  def update_from_params(params, _current_user)
    params["instructions"] = [instructions, params["instructions"]].flatten if params.key?("instructions")
    update(params)
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
    sub_task ? sub_task.attorney_case_reviews.order(:created_at).last : nil
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

  # TODO: parent/grand parents/etc should be able to modify children/grandchildren/etc
  # check if assigned to is part of the judge team
  def can_user_access?(user)
    return true if assigned_to == user || (parent && parent.assigned_to == user)
    false
  end

  def verify_user_access(user)
    unless can_user_access?(user)
      fail Caseflow::Error::ActionForbiddenError, message: "Current user cannot access this task"
    end
  end

  def self.verify_user_can_assign(user)
    unless user.attorney_in_vacols? ||
           (user.judge_in_vacols? && FeatureToggle.enabled?(:judge_assignment_to_attorney, user: user))
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

  def assignable_organizations
    Organization.assignable(self)
  end

  def assignable_users
    if assigned_to.is_a?(Organization)
      assigned_to.members
    elsif parent && parent.assigned_to.is_a?(Organization)
      parent.assigned_to.members.reject { |member| member == assigned_to }
    else
      []
    end
  end

  private

  def sub_task
    children.first
  end

  def update_status_if_children_tasks_are_complete
    if children.any? && children.reject { |t| t.status == Constants.TASK_STATUSES.completed }.empty?
      return mark_as_complete! if assigned_to.is_a?(Organization)
      return update!(status: :assigned) if on_hold?
    end
  end

  def on_hold_duration_is_set
    if saved_change_to_status? && on_hold? && !on_hold_duration && colocated_task?
      errors.add(:on_hold_duration, "has to be specified")
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
