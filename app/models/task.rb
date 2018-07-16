class Task < ApplicationRecord
  belongs_to :assigned_to, class_name: "User"
  belongs_to :assigned_by, class_name: "User"
  belongs_to :appeal, polymorphic: true

  validates :assigned_to, :assigned_by, :appeal, :type, :status, presence: true
  validate :on_hold_duration_is_set, on: :update
  before_create :set_assigned_at
  before_update :set_timestamps

  after_update :update_location_in_vacols

  enum status: {
    assigned: "assigned",
    in_progress: "in_progress",
    on_hold: "on_hold",
    completed: "completed"
  }

  private

  def update_location_in_vacols
    if saved_change_to_status? &&
       completed? &&
       appeal_type == "LegacyAppeal" &&
       appeal.tasks.map(&:status).uniq == ["completed"]
      AppealRepository.update_location!(appeal, assigned_by.vacols_uniq_id)
    end
  end

  def set_assigned_at
    self.assigned_at = created_at
  end

  def set_timestamps
    if will_save_change_to_status?
      self.started_at = updated_at if in_progress?
      self.placed_on_hold_at = updated_at if on_hold?
      self.completed_at = updated_at if completed?
    end
  end

  def on_hold_duration_is_set
    if saved_change_to_status? && on_hold? && !on_hold_duration
      errors.add(:on_hold_duration, "has to be specified")
    end
  end
end
