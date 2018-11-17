class CaseReviewsController < ApplicationController
  CASE_REVIEW_CLASSES = {
    AttorneyCaseReview: AttorneyCaseReview,
    JudgeCaseReview: JudgeCaseReview
  }.freeze

  rescue_from Caseflow::Error::UserRepositoryError do |e|
    render(e.serialize_response)
  end

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def complete
    return invalid_type_error unless case_review_class

    record = case_review_class.complete(complete_params)
    return invalid_record_error(record) unless record.valid?

    create_quality_review_task(record) if case_review_class == JudgeCaseReview

    response = { task: record }
    response[:issues] = record.appeal.issues
    render json: response
  end

  private

  def create_quality_review_task(record)
    return if record.appeal.class == LegacyAppeal
    QualityReviewTask.create_from_root_task(record.task.root_task) if record.task.parent.type != QualityReviewTask.name
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
    }, status: 400
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
                                   issues: [:id, :disposition, :readjudication,
                                            remand_reasons: [:code, :post_aoj]])
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
                                   issues: [:id, :disposition, :readjudication,
                                            remand_reasons: [:code, :post_aoj]])
      .merge(judge: current_user, task_id: params[:task_id])
  end
end
