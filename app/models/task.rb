class Task < ActiveRecord::Base
  belongs_to :user
  belongs_to :appeal

  class AlreadyAssignedError < StandardError; end

  DEPARTMENT_MAPPING = {
    EstablishClaim: :dispatch
  }.freeze

  COMPLETION_STATUS_MAPPING = {
    0 => "Completed",
    1 => "Cancelled",

    # Establish Claim completion codes
    2 => "Routed to RO"
  }.freeze

  class << self
    def unassigned
      where(user_id: nil)
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
  end

  def start_text
    type.titlecase
  end

  def url_path
    department = DEPARTMENT_MAPPING[type.to_sym]
    "/#{department}/#{type.underscore.dasherize}/#{id}"
  end

  def assign!(user)
    return AlreadyAssignedError if self.user

    update_attributes!(
      user: user,
      assigned_at: Time.now.utc
    )
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
  def completed(status)
    update_attributes!(
      completed_at: Time.now.utc,
      completion_status: status
    )
  end

  def completion_status_text
    COMPLETION_STATUS_MAPPING[completion_status]
  end
end
