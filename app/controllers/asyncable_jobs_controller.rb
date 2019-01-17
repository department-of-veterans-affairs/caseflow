class AsyncableJobsController < ApplicationController
  before_action :verify_access, :react_routed, :set_application

  def index
    if allowed_params[:asyncable_job_klass]
      @jobs = asyncable_job_klass.expired_without_processing
    end
  end

  def show
    render json: job.asyncable_ui_hash
  end

  def update
    job.restart!
    render json: job.asyncable_ui_hash
  end

  private

  helper_method :jobs, :job

  def asyncable_job_klass
    klass = allowed_params[:asyncable_job_klass].constantize
    fail ActiveRecord::RecordNotFound unless asyncable_models.include?(klass)

    klass
  end

  def jobs
    @jobs ||= gather_jobs
  end

  def job
    @job ||= allowed_params[:asyncable_job_klass].constantize.find(allowed_params[:id])
  end

  # TODO: how to support paging when coallescing so many different models?
  def gather_jobs
    expired_jobs = []
    asyncable_models.each do |klass|
      expired_jobs << klass.expired_without_processing
    end
    expired_jobs.flatten.sort_by(&:submitted_at_dtim)
  end

  def asyncable_models
    ActiveRecord::Base.descendants.select { |c| c.included_modules.include?(Asyncable) }
      .reject(&:abstract_class?)
      .map(&:name)
      .map(&:constantize)
  end

  def set_application
    RequestStore.store[:application] = "asyncable_jobs"
  end

  def verify_access
    return true if current_user.can?("Admin Intake")

    Rails.logger.info("User with roles #{current_user.roles.join(', ')} "\
      "couldn't access #{request.original_url}")

    session["return_to"] = request.original_url
    redirect_to "/unauthorized"
  end

  def allowed_params
    params.permit(:asyncable_job_klass, :id)
  end
end
