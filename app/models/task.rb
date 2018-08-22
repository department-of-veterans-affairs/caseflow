class Task < ApplicationRecord
  acts_as_tree

  belongs_to :assigned_to, polymorphic: true
  belongs_to :assigned_by, class_name: "User"
  belongs_to :appeal, polymorphic: true

  validates :assigned_to, :appeal, :type, :status, presence: true

  before_create :set_assigned_at_and_update_parent_status
  before_update :set_timestamps

  after_update :update_parent_status

  validate :on_hold_duration_is_set, on: :update

  enum status: {
    assigned: "assigned",
    in_progress: "in_progress",
    on_hold: "on_hold",
    completed: "completed"
  }

  def assigned_by_display_name
    if assigned_by.try(:full_name)
      return assigned_by.full_name.split(" ")
    end

    ["", ""]
  end

  def legacy?
    appeal_type == "LegacyAppeal"
  end

  def ama?
    appeal_type == "Appeal"
  end

  def colocated_task?
    type == "ColocatedTask"
  end

  def mark_as_complete!
    update!(status: :completed)
    parent.when_child_task_completed if parent
  end

  def when_child_task_completed
    update_status_if_children_tasks_are_complete
  end

  def update_status_if_children_tasks_are_complete
    if children.reject { |t| t.status == "completed" }.empty?
      return mark_as_complete! if assigned_to.is_a?(Organization)
      return update!(status: :assigned) if on_hold?
    end
  end

  private

  def on_hold_duration_is_set
    if saved_change_to_status? && on_hold? && !on_hold_duration && colocated_task?
      errors.add(:on_hold_duration, "has to be specified")
    end
  end

  def update_parent_status
    parent.update_status_if_children_tasks_are_complete if saved_change_to_status? && parent
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
