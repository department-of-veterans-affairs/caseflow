class CaseReviewsController < ApplicationController
  CASE_REVIEW_CLASSES = {
    AttorneyCaseReview: AttorneyCaseReview,
    JudgeCaseReview: JudgeCaseReview
  }.freeze

  rescue_from Caseflow::Error::UserRepositoryError do |e|
    handle_non_critical_error("case_reviews", e)
  end

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def complete
    return invalid_type_error unless case_review_class

    record = case_review_class.complete(complete_params)
    return invalid_record_error(record) unless record.valid?

    create_quality_review_task(record)

    response = { task: record }
    response[:issues] = record.appeal.issues
    render json: response
  end

  def update
    result = UpdateAttorneyCaseReview.new(
      id: params[:id],
      user_id: current_user.id,
      document_id: params[:document_id]
    ).call

    render json: result.to_h, status: result.success? ? :ok : :bad_request
  end

  private

  def create_quality_review_task(record)
    return if record.appeal.is_a?(LegacyAppeal) ||
              !record.is_a?(JudgeCaseReview) ||
              record.task.parent.is_a?(QualityReviewTask)

    root_task = record.task.root_task
    if QualityReviewCaseSelector.select_case_for_quality_review?
      QualityReviewTask.create_from_root_task(root_task)
    else
      BvaDispatchTask.create_from_root_task(root_task)
    end
  end

  def case_review_class
    CASE_REVIEW_CLASSES[params["tasks"][:type].try(:to_sym)]
  end

  def invalid_type_error
    render json: {
      "errors": [
        "title": "Invalid Case Review Type Error",
        "detail": "Case review type is invalid, valid types: #{CASE_REVIEW_CLASSES.keys}"
      ]
    }, status: :bad_request
  end

  def complete_params
    return attorney_case_review_params if case_review_class == AttorneyCaseReview
    return judge_case_review_params if case_review_class == JudgeCaseReview
  end

  def attorney_case_review_params
    params.require("tasks").permit(:document_type,
                                   :reviewing_judge_id,
                                   :document_id,
                                   :work_product,
                                   :overtime,
                                   :note,
                                   issues: issues_params)
      .merge(attorney: current_user, task_id: params[:task_id])
  end

  def judge_case_review_params
    params.require("tasks").permit(:location,
                                   :attorney_id,
                                   :complexity,
                                   :quality,
                                   :comment,
                                   :one_touch_initiative,
                                   factors_not_considered: [],
                                   areas_for_improvement: [],
                                   issues: issues_params)
      .merge(judge: current_user, task_id: params[:task_id])
  end

  def issues_params
    # This is a combined list of params from the old and new issue editing methods.
    # If new params like request_issue_ids exist in the request, we default to
    # using the new issue editing flow.
    [
      :id,
      :disposition,
      :description,
      :readjudication,
      :benefit_type,
      :diagnostic_code,
      request_issue_ids: [],
      remand_reasons: [
        :code,
        :post_aoj
      ]
    ]
  end

  def ama?
    params["task_id"] !~ LegacyTask::TASK_ID_REGEX
  end
end
