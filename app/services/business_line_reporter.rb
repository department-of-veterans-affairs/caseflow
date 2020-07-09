# frozen_string_literal: true

class BusinessLineReporter
  attr_reader :business_line

  BUSINESS_LINE_OPTIONS = %w[type appeal_type id appeal_id claimant_name created_at
                             closed_at tasks_url business_line request_issue_count
                             decision_issues_count veteran_file_number user_id].freeze

  def initialize(business_line)
    @business_line = business_line
  end

  def tasks
    business_line.tasks.completed.all.includes([:assigned_to, :appeal]).order(id: :asc)
  end

  # rubocop:disable Metrics/AbcSize
  def as_csv
    CSV.generate do |csv|
      csv << BUSINESS_LINE_OPTIONS
      tasks.each do |task|
        csv << [
          task.type,
          task.appeal_type,
          task.id,
          task.appeal_id,
          task.appeal.claimant.name,
          task.created_at.strftime("%Y-%m-%d"),
          task.closed_at.strftime("%Y-%m-%d"),
          "https://appeals.cf.ds.va.gov#{business_line.tasks_url}/tasks/#{task.id}",
          business_line.name,
          task.appeal.request_issues.count,
          task.appeal.decision_issues.count,
          task.appeal.veteran_file_number,
          task.appeal.intake.user.css_id
        ].flatten
      end
    end
  end
  # rubocop:enable Metrics/AbcSize
end
