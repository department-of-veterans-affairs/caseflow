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

  helper_method :jobs, :job, :allowed_params

  def asyncable_job_klass
    klass = allowed_params[:asyncable_job_klass].constantize
    fail ActiveRecord::RecordNotFound unless asyncable_jobs.models.include?(klass)

    klass
  end

  def asyncable_jobs
    @asyncable_jobs ||= AsyncableJobs.new
  end

  def jobs
    @jobs ||= asyncable_jobs.jobs
  end

  def job
    @job ||= allowed_params[:asyncable_job_klass].constantize.find(allowed_params[:id])
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
