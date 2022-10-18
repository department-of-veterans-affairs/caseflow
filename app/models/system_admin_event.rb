# frozen_string_literal: true

class SystemAdminEvent < CaseflowRecord
  belongs_to :user, optional: false

  validates :type, presence: true

  enum type: {
    veteran_extract: "veteran_extract",
    ran_scheduled_job: "ran_scheduled_job"
  }
end
