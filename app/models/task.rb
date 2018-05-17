class Task < ApplicationRecord
  belongs_to :assigned_to, class_name: "User"
  belongs_to :assigned_by, class_name: "User"
  # TODO: add polymorphic association
  belongs_to :appeal, class_name: "LegacyAppeal"

  validates :assigned_to, :assigned_by, :appeal, :type, :status, presence: true

  enum status: {
    assigned: "assigned",
    in_progress: "in_progress",
    on_hold: "on_hold",
    completed: "completed"
  }
end
