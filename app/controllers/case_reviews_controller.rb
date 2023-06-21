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
      if case_review.appeal_type == "Appeal" &&
         (FeatureToggle.enabled?(:mst_identification) || FeatureToggle.enabled?(:pact_identification))
        appeal = Appeal.find(case_review.appeal_id)
        update_request_issues_for_mst_and_pact(appeal)
      end
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


  def update_request_issues_for_mst_and_pact(appeal)
    params[:tasks][:issues].each do |issue|
      RequestIssue.find(issue[:request_issue_ids]).each do |ri|
        if !issue[:mstStatus].nil? && !issue[:pactStatus].nil?
          if ri.mst_status != issue[:mstStatus] || ri.pact_status != issue[:pactStatus]
            create_issue_update_task(ri, issue, appeal)
          end
        end
        ri.update(mst_status: issue[:mstStatus], pact_status: issue[:pactStatus])
      end
    end
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

  def create_issue_update_task(original_issue, incoming_issue_update, appeal)
    root_task = RootTask.find_or_create_by!(appeal: appeal)

    task = IssuesUpdateTask.create!(
      appeal: appeal,
      parent: root_task,
      assigned_to: SpecialIssueEditTeam.singleton,
      assigned_by: RequestStore[:current_user],
      completed_by: RequestStore[:current_user]
    )

    task.format_instructions(
      "Edited Issue",
      [original_issue.nonrating_issue_category, original_issue.contested_issue_description].join,
      original_issue.mst_status,
      original_issue.pact_status,
      incoming_issue_update[:mstStatus],
      incoming_issue_update[:pactStatus]
    )

    task.completed!
  end
end
