class Task < ApplicationRecord
  belongs_to :assigned_to, class_name: "User"
  belongs_to :assigned_by, class_name: "User"
  belongs_to :appeal, class_name: "LegacyAppeal"

  validates :assigned_to, :assigned_by, :appeal, :type, :status, presence: true
  after_create :set_assigned_at

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
end
