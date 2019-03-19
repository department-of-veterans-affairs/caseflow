class CloseIneligibleIssues < ActiveRecord::Migration[5.1]
  def change
    RequestIssue.where.not(ineligible_reason: nil).each do |issue|
      if !issue.decision_review
        issue.update!(closed_at: Time.zone.now, closed_status: :ineligible)
      end

      intake = Intake.where(completion_status: "success").find_by(detail: issue.decision_review)
      issue.update!(closed_at: intake&.completed_at || Time.zone.now, closed_status: :ineligible)
    end
  end
end