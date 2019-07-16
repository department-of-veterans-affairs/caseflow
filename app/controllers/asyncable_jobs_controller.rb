# frozen_string_literal: true

class AsyncableJobsController < ApplicationController
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

  def pagination
    {
      page_size: page_size,
      current_page: current_page,
      total_pages: total_pages,
      total_jobs: total_jobs
    }
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

  def total_pages
    total_pages = (total_jobs / page_size).to_i
    total_pages += 1 if total_jobs % page_size
    total_pages
  end

  def page_size
    50 # TODO: allowed param?
  end

  def current_page
    (allowed_params[:page] || 1).to_i
  end

  def page_start
    return 0 if current_page < 2

    (current_page - 1) * page_size
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
    params.permit(:asyncable_job_klass, :id, :page)
  end
end
