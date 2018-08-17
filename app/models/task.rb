class Task < ApplicationRecord
  acts_as_tree

  belongs_to :assigned_to, polymorphic: true
  belongs_to :assigned_by, class_name: "User"
  belongs_to :appeal, polymorphic: true

  validates :assigned_to, :appeal, :type, :status, presence: true

  before_create :set_assigned_at_and_update_parent_status
  before_update :set_timestamps

  after_update :update_location_in_vacols, :update_parent_status

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

  private

  def on_hold_duration_is_set
    if saved_change_to_status? && on_hold? && !on_hold_duration && type == "ColocatedTask"
      errors.add(:on_hold_duration, "has to be specified")
    end
  end

  def update_parent_status
    if saved_change_to_status? && completed? && parent
      parent.update(status: :assigned)
    end
  end

  def update_location_in_vacols
    if saved_change_to_status? &&
       completed? &&
       appeal_type == "LegacyAppeal" &&
       appeal.tasks.map(&:status).uniq == ["completed"]
      AppealRepository.update_location!(appeal, assigned_by.vacols_uniq_id)
    end
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
