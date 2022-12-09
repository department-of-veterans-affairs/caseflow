# frozen_string_literal: true

class BusinessLine < Organization
  def tasks_url
    "/decision_reviews/#{url}"
  end

  # :reek:FeatureEnvy
  def in_progress_tasks
    tasks.open.includes([:assigned_to, :appeal]).order(assigned_at: :desc).select do |task|
      if FeatureToggle.enabled?(:board_grant_effectuation_task, user: :current_user)
        task.is_a?(BoardGrantEffectuationTask) || task.appeal.request_issues.active.any?
      else
        task.appeal.request_issues.active.any?
      end
    end
  end

  def completed_tasks
    tasks.recently_completed.includes([:assigned_to, :appeal]).order(closed_at: :desc)
  end
end
