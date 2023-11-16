# frozen_string_literal: true

namespace :ama_appeals_awaiting_judge_action do
  task generate_csv: [:environment] do
    decision_issues = DecisionIssue.joins(:remand_reasons)
      .where("remand_reasons.code IN (?)", %w[medical_examinations medical_opinions])
      .where(decision_review_type: "Appeal")

    csv_file = Rails.root.join("reports/ama_appeals_awaiting_judge_action_data.csv")
    CSV.open(csv_file, "wb") do |csv|
      csv << ["Docket ID", "Assigned Task", "Task Assigned", "Assigned to", "Notes"]
      decision_issues.each do |decision_issue|
        appeal = decision_issue.decision_review
        tasks = appeal.tasks.where(type: "JudgeDecisionReviewTask").where.not(status: "completed")
        tasks.each do |task|
          csv << [
            appeal.docket_number,
            task.type,
            task.assigned_at&.strftime("%d-%b-%y"),
            task.assigned_to&.full_name,
            JudgeCaseReview.find_by(task_id: task.id, appeal: appeal)&.comment
          ]
        end
      end
    end
  end
end
