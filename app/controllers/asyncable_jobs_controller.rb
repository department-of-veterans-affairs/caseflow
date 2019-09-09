# frozen_string_literal: true

class AsyncableJobsController < ApplicationController
  include PaginationConcern

  before_action :verify_access, :react_routed, :set_application

  def index
    if allowed_params[:asyncable_job_klass]
      @jobs = asyncable_job_klass.potentially_stuck.limit(page_size).offset(page_start)
    end
  end

  def show
    respond_to do |format|
      format.json { render json: job.asyncable_ui_hash }
      format.html { render template: "asyncable_jobs/show" }
    end
  end

  def update
    job.restart!
    render json: job.asyncable_ui_hash
  end

  private

  helper_method :jobs, :job, :allowed_params, :pagination

  def asyncable_job_klass
    klass = allowed_params[:asyncable_job_klass].constantize
    fail ActiveRecord::RecordNotFound unless AsyncableJobs.models.include?(klass)

    klass
  end

  def asyncable_jobs
    @asyncable_jobs ||= AsyncableJobs.new(page_size: page_size, page: current_page)
  end

  def total_jobs
    @total_jobs ||= begin
      if allowed_params[:asyncable_job_klass]
        asyncable_job_klass.potentially_stuck.count
      else
        asyncable_jobs.total_jobs
      end
    end
  end

  alias total_items total_jobs

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
    params.permit(:asyncable_job_klass, :id, :page)
  end
end
