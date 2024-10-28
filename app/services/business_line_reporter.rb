# frozen_string_literal: true

class BusinessLineReporter
  attr_reader :business_line, :filters

  BUSINESS_LINE_OPTIONS = %w[business_line appeal_id appeal_type claimant_name request_issues_count
                             decision_issues_count veteran_file_number intake_user_id
                             task_type task_id tasks_url task_assigned_to created_at closed_at].freeze

  def initialize(business_line, filters = nil)
    @business_line = business_line
    @filters = { filters: filters, sort_by: :id, sort_order: :asc }
  end

  def tasks
    # If it is the VhaBusinessLine use the decision review queue task methods since they support the filters
    if business_line.is_a?(VhaBusinessLine)
      business_line.completed_tasks(filters).includes(
        [:assigned_to, appeal: [:request_issues, :decision_issues, intake: [:user]]]
      )
    else
      business_line.tasks.completed.includes(
        [:assigned_to, appeal: [:request_issues, :decision_issues, intake: [:user]]]
      ).order(id: :asc)
    end
  end

  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/MethodLength
  def as_csv
    CSV.generate do |csv|
      csv << BUSINESS_LINE_OPTIONS
      tasks.each do |task|
        csv << [
          business_line.name,
          task.appeal_id,
          task.appeal.class.review_title,
          task.appeal.claimant&.name,
          task.appeal.request_issues.size,
          task.appeal.decision_issues.size,
          task.appeal.veteran_file_number,
          task.appeal.intake&.user&.css_id,
          task.type,
          task.id,
          "https://appeals.cf.ds.va.gov#{business_line.tasks_url}/tasks/#{task.id}",
          task.assigned_to.try(:name) || task.assigned_to.try(:css_id),
          task.created_at.strftime("%Y-%m-%d"),
          task.closed_at.strftime("%Y-%m-%d")
        ].flatten
      end
    end
  end
  # rubocop:enable Metrics/MethodLength
  # rubocop:enable Metrics/AbcSize
end
