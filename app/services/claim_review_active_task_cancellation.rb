# frozen_string_literal: true

class ClaimReviewActiveTaskCancellation
  def initialize(review)
    @review = review
  end

  def call
    review.tasks.each(&:cancel_task_and_child_subtasks) if no_active_request_issues?
  end

  private

  attr_reader :review

  def no_active_request_issues?
    review.request_issues.active.empty?
  end
end
