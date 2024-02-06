# frozen_string_literal: true

class CaseReviewsController < ApplicationController
  rescue_from Caseflow::Error::UserRepositoryError do |e|
    handle_non_critical_error("case_reviews", e)
  end

  def set_application
    RequestStore.store[:application] = "queue"
  end

  def complete
    new_complete_case_review = CompleteCaseReview.new(case_review_class: case_review_class, params: complete_params)
    result = new_complete_case_review.call
    if result.success?
      case_review = result.extra[:case_review]
      render json: {
        task: case_review,
        issues: case_review.appeal.issues
      }
    else
      render json: result.to_h, status: :bad_request
    end
  end

  def update
    update_case_review_class = (params[:legacy] == true) ? UpdateLegacyAttorneyCaseReview : UpdateAttorneyCaseReview
    result = update_case_review_class.new(
      id: params[:id],
      user: current_user,
      document_id: params[:document_id]
    ).call

    render json: result.to_h, status: result.success? ? :ok : :bad_request
  end

  private

  def case_review_class
    params["tasks"].fetch(:type)
  end

  def complete_params
    return attorney_case_review_params if case_review_class == "AttorneyCaseReview"
    return judge_case_review_params if case_review_class == "JudgeCaseReview"
  end

  def attorney_case_review_params
    params.require("tasks").permit(:document_type,
                                   :reviewing_judge_id,
                                   :document_id,
                                   :work_product,
                                   :overtime,
                                   :untimely_evidence,
                                   :note,
                                   issues: issues_params)
      .merge(attorney: current_user, task_id: params[:task_id])
  end

  def judge_case_review_params
    params.require("tasks").permit(:location,
                                   :attorney_id,
                                   :timeliness,
                                   :complexity,
                                   :quality,
                                   :comment,
                                   :one_touch_initiative,
                                   factors_not_considered: [],
                                   areas_for_improvement: [],
                                   positive_feedback: [],
                                   issues: issues_params)
      .merge(judge: current_user, task_id: params[:task_id])
  end

  def issues_params
    # This is a combined list of params for ama and legacy appeals
    # Reprsents the information the front end is sending to create a decision issue object
    [
      :id,
      :disposition,
      :description,
      :readjudication,
      :benefit_type,
      :diagnostic_code,
      :mst_status,
      :pact_status,
      request_issue_ids: [],
      remand_reasons: [
        :code,
        :post_aoj
      ]
    ]
  end
end
