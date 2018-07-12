class Task < ApplicationRecord
  belongs_to :assigned_to, class_name: "User"
  belongs_to :assigned_by, class_name: "User"
  belongs_to :appeal, polymorphic: true

  validates :assigned_to, :assigned_by, :appeal, :type, :status, presence: true
  validate :on_hold_duration_is_set, on: :update
  before_create :set_assigned_at
  before_update :set_timestamps

  enum status: {
    assigned: "assigned",
    in_progress: "in_progress",
    on_hold: "on_hold",
    completed: "completed"
  }

  private

  def set_assigned_at
    self.assigned_at = created_at
  end

  def set_timestamps
    return unless status_changed?
    self.started_at = updated_at if in_progress?
    self.placed_on_hold_at = updated_at if on_hold?
  end

  def on_hold_duration_is_set
    if status_changed? && on_hold? && !on_hold_duration
      errors.add(:on_hold_duration, "has to be specified")
    end
  end
end
