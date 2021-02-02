# frozen_string_literal: true

class NodDateUpdate < CaseflowRecord
  belongs_to :appeal
  belongs_to :user

  validates :appeal, :user, :old_date, :new_date, :change_reason, presence: true
  #validate :validate_all_issues_timely

  delegate :request_issues, to: :appeal
  #delegate :validate_all_issues_timely, to: :appeal

  # def validate_all_issues_timely!(new_date)
  #   affected_issues = request_issues.reject { |request_issue| request_issue.timely_issue?(new_date.to_date) }
  #   unaffected_issues = request_issues - affected_issues

  #   return true if affected_issues.blank?

  #   timeliness_error = {
  #     message: "Timeliness of one or more issues is affected by NOD date change",
  #     affected_issues: affected_issues,
  #     unaffected_issues: unaffected_issues
  #   }
  #   errors.add(:new_date, timeliness_error)
  # end

  enum change_reason: {
    entry_error: "entry_error",
    new_info: "new_info"
  }
end
