class CompleteCaseReview
  include ActiveModel::Model

  def initialize(case_review_class:, params:)
    @case_review_class = case_review_class
    @params = params
  end

  def call
    @success = case_review.valid?

    create_quality_review_task if success

    FormResponse.new(success: success, errors: [response_errors], extra: completed_case_review)
  end

  private

  attr_reader :case_review_class, :params, :success

  def case_review
    @case_review ||= review_class.complete(params)
  end

  def review_class
    case_review_class.constantize
  end

  def create_quality_review_task
    return if case_review.appeal.is_a?(LegacyAppeal) ||
              !case_review.is_a?(JudgeCaseReview) ||
              case_review.task.parent.is_a?(QualityReviewTask)

    root_task = case_review.task.root_task
    if QualityReviewCaseSelector.select_case_for_quality_review?
      QualityReviewTask.create_from_root_task(root_task)
    else
      BvaDispatchTask.create_from_root_task(root_task)
    end
  end

  def response_errors
    return if success

    {
      title: "Record is invalid",
      detail: case_review.errors.full_messages.join(", ")
    }
  end

  def completed_case_review
    return {} unless success

    { case_review: case_review }
  end
end
