# frozen_string_literal: true

class BusinessLine < Organization
  delegate :in_progress_tasks, :completed_tasks, to: :decision_review_tasks_query_manager

  def tasks_url
    "/decision_reviews/#{url}"
  end

  private

  def decision_review_tasks_query_manager
    @decision_review_tasks_query_manager ||= DecisionReviewTasksQueryManager.new(self)
  end
end
