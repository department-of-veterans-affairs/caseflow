class Task < ActiveRecord::Base
  belongs_to :user
  belongs_to :appeal

  class << self

    COMPLETION_STATUS_MAPPING = {
      0 => "Completed",
      1 => "Cancelled by User",
      2 => "Cancelled by System",
      3 => "Routed to RO"
    }.freeze

    def unassigned
      where(user_id: nil)
    end

    def assigned_not_completed
      to_complete.where.not(assigned_at: nil)
    end 

    def newest_first
      order(created_at: :desc)
    end

    def completed_today
      where(completed_at: DateTime.now.beginning_of_day.utc..DateTime.now.end_of_day.utc)
    end

    def to_complete
      where(completed_at: nil)
    end

    def completed
      where.not(completed_at: nil)
    end

    def completion_status_code(code)
      COMPLETION_STATUS_MAPPING.key(code)
    end
  end

  def start_text
    type.titlecase
  end

  def assign!(user)
    update_attributes!(
      user: user,
      assigned_at: Time.now.utc
    )
    self
  end

  def unassign!
    update_attributes!(
      user: nil,
      assigned_at: nil,
      started_at: nil,
    )
  end

  def duplicate_and_mark_complete!
    EstablishClaim.create!(appeal_id: appeal_id)
    completed!(self.class.completion_status_code("Cancelled by System"))
  end

  def assigned?
    assigned_at
  end

  def progress_status
    if completed_at
      "Complete"
    elsif started_at
      "In Progress"
    elsif assigned_at
      "Not Started"
    else
      "Unassigned"
    end
  end

  def complete?
    completed_at
  end

  # completion_status is 0 for success, or non-zero to specify another completed case
  def completed!(status)
    update_attributes!(
      completed_at: Time.now.utc,
      completion_status: status
    )
  end

  def completion_status_text
    COMPLETION_STATUS_MAPPING[completion_status]
  end
end
