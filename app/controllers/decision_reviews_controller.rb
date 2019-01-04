class DecisionReviewsController < ApplicationController
  before_action :verify_access, :react_routed, :verify_feature_enabled, :set_application

  def index
    if business_line
      render "index"
    else
      # TODO: make index show error message
      render json: { error: "#{business_line_slug} not found" }, status: 404
    end
  end

  def show
    if task
      render "show"
    else
      render json: { error: "Task #{task_id} not found" }, status: 404
    end
  end

  def business_line_slug
    allowed_params[:business_line_slug] || allowed_params[:decision_review_business_line_slug]
  end

  def task_id
    allowed_params[:task_id]
  end

  def task
    @task ||= DecisionReviewTask.find(task_id)
  end

  def in_progress_tasks
    apply_task_serializer(business_line.tasks.reject(&:completed?))
  end

  def completed_tasks
    apply_task_serializer(business_line.tasks.select(&:completed?))
  end

  def business_line
    @business_line ||= BusinessLine.find_by(url: business_line_slug)
  end

  helper_method :in_progress_tasks, :completed_tasks, :business_line, :task

  private

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
    params.permit(:decision_review_business_line_slug, :business_line_slug, :task_id)
  end
end
