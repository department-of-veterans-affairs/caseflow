# frozen_string_literal: true

require "csv"

class BusinessLineReporter
  attr_reader :business_line

  def initialize(business_line)
    @business_line = business_line
  end

  def tasks
    business_line.tasks.completed
  end

  def as_csv
    CSV.generate do |csv|
      csv << %w[type id appeal_id claimant_name created_at closed_at tasks_url business_line request_issue_count decision_issues_count veteran_file_number user_id]
      tasks.each do |task|
        csv << [
          task.type,
          task.id,
          task.appeal_id,
          task.appeal.claimant.name,
          task.created_at.strftime("%Y-%m-%d"),
          task.closed_at.strftime("%Y-%m-%d"),
          business_line.tasks_url,
          business_line.name,
          task.appeal.request_issues.count,
          task.appeal.decision_issues.count,
          task.appeal.veteran_file_number,
          task.appeal.intake.user.css_id
        ].flatten
      end
    end
  end
end
