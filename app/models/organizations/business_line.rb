# frozen_string_literal: true

class BusinessLine < Organization
  def tasks_url
    "/decision_reviews/#{url}"
  end

  def in_progress_tasks(user)
    grant_effectuations = FeatureToggle.enabled?(:board_grant_effectuation_task, user: user)
    tasks.open.includes(:assigned_to, appeal: [:request_issues]).order(assigned_at: :desc).select do |task|
      if grant_effectuations
        task_has_active_request_issues?(task) || task.is_a?(BoardGrantEffectuationTask)
      else
        task_has_active_request_issues?(task)
      end
    end
  end

  private

  def task_has_active_request_issues?(task)
    # Using request_issues.active forces ActiveRecord to do a new SQL query, but we eager-load the associations
    # in in_progress_tasks, so this is undesirable. Instead, fetch all request issues and see if any are active:
    task.appeal.request_issues.any?(&:active?)
  end
end
