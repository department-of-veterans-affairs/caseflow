class DecisionReviewsController < ApplicationController
  before_action :verify_access, :react_routed, :verify_feature_enabled, :set_application

  def index
    if business_line
      render "index"
    else
      # TODO: make index show error message
      render json: { error: "#{business_line_slug} not found" }, status: :not_found
    end
  end

  def show
    if task
      render "show"
    else
      render json: { error: "Task #{task_id} not found" }, status: :not_found
    end
  end

  def update
    if task
      if task.complete_with_payload!(decision_issue_params, decision_date)
        business_line.tasks.reload
        render json: { in_progress_tasks: in_progress_tasks, completed_tasks: completed_tasks }, status: :ok
      else
        render json: { error_code: task.error_code }, status: :bad_request
      end
    else
      render json: { error: "Task #{task_id} not found" }, status: :not_found
    end
  end

  def business_line_slug
    allowed_params[:business_line_slug] || allowed_params[:decision_review_business_line_slug]
  end

  def task_id
    allowed_params[:task_id]
  end

  def task
    @task ||= Task.includes([:appeal, :assigned_to]).find(task_id)
  end

  def in_progress_tasks
    apply_task_serializer(
      business_line.tasks.active.includes([:assigned_to, :appeal]).order(assigned_at: :desc)
    )
  end

  def completed_tasks
    apply_task_serializer(
      business_line.tasks.includes([:assigned_to, :appeal]).order(closed_at: :desc).select(&:completed?)
    )
  end

  def business_line
    @business_line ||= BusinessLine.find_by(url: business_line_slug)
  end

  helper_method :in_progress_tasks, :completed_tasks, :business_line, :task

  private

  def decision_date
    return unless task.instance_of? DecisionReviewTask

    Date.parse(allowed_params.require("decision_date")).to_datetime
  end

  def decision_issue_params
    return unless task.instance_of? DecisionReviewTask

    allowed_params.require("decision_issues").map do |decision_issue_param|
      decision_issue_param.permit(:request_issue_id, :disposition, :description)
    end
  end

  def apply_task_serializer(tasks)
    tasks.map { |task| task.ui_hash.merge(business_line: business_line_slug) }
  end

  def set_application
    RequestStore.store[:application] = "decision_reviews"
  end

  # TODO: authz rules for this space
  def verify_access
    return false unless business_line
    return true if current_user.admin?
    return true if business_line.user_has_access?(current_user)

    Rails.logger.info("User with roles #{current_user.roles.join(', ')} "\
      "couldn't access #{request.original_url}")

    session["return_to"] = request.original_url
    redirect_to "/unauthorized"
  end

  def verify_feature_enabled
    redirect_to "/unauthorized" unless FeatureToggle.enabled?(:decision_reviews)
  end

  def allowed_params
    params.permit(
      :decision_review_business_line_slug,
      :decision_review,
      :decision_date,
      :business_line_slug,
      :task_id,
      decision_issues: [:description, :disposition, :request_issue_id]
    )
  end
end
