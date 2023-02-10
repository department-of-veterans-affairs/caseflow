# frozen_string_literal: true

class AsyncableJobsController < ApplicationController
  include PaginationConcern

  before_action :react_routed, :set_application
  before_action :verify_access, only: [:index, :start_job]
  before_action :verify_job_access, only: [:show]
  skip_before_action :deny_vso_access

  def index
    if asyncable_job_klass
      @jobs = asyncable_job_klass.potentially_stuck.limit(page_size).offset(page_start)
    end
    respond_to do |format|
      format.json { render json: jobs.map(&:asyncable_ui_hash) }
      format.html
      format.csv do
        jobs_as_csv = AsyncableJobsReporter.new(jobs: all_jobs).as_csv
        filename = Time.zone.now.strftime("async-jobs-%Y%m%d.csv")
        send_data jobs_as_csv, filename: filename
      end
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

  def add_note
    send_to_intake_user = ActiveRecord::Type::Boolean.new.deserialize(allowed_params[:send_to_intake_user])
    messaging = AsyncableJobMessaging.new(job: job, user: current_user)
    job_note = messaging.add_job_note(
      text: allowed_params[:note],
      send_to_intake_user: send_to_intake_user
    )
    render json: job_note.serialize
  end

  def start_job
    # start job asynchronously as given by the job_type post param
    job = SCHEDULED_JOBS[allowed_params[:job_type]]
    return unrecognized_job unless job

    success = true

    begin
      if allowed_params[:run_async]
        job.perform_later
      else
        job.perform_now
      end
    rescue Exception => e
      verb = allowed_params[:run_async] ? "Scheduling" : "Manual run"
      Rails.logger.error "#{verb} of #{allowed_params[:job_type]} failed : #{e.message}"
      success = false
    end

    render json: { success: success }, status: :ok
  end

  private

  helper_method :jobs, :job, :allowed_params, :pagination, :supported_jobs

  def asyncable_job_klass
    @asyncable_job_klass ||= begin
      if allowed_params[:asyncable_job_klass]
        klass = allowed_params[:asyncable_job_klass].constantize
        fail ActiveRecord::RecordNotFound unless AsyncableJobs.models.include?(klass)

        klass
      end
    end
  end

  def asyncable_jobs
    @asyncable_jobs ||= AsyncableJobs.new(
      page_size: page_size,
      page: current_page,
      veteran_file_number: veteran_file_number
    )
  end

  def total_jobs
    @total_jobs ||= begin
      if asyncable_job_klass
        asyncable_job_klass.potentially_stuck.count
      else
        asyncable_jobs.total_jobs
      end
    end
  end

  alias total_items total_jobs

  def all_jobs
    @all_jobs ||= begin
      if asyncable_job_klass
        asyncable_job_klass.potentially_stuck
      else
        AsyncableJobs.new(page_size: 0).jobs
      end
    end
  end

  def jobs
    @jobs ||= asyncable_jobs.jobs
  end

  def job
    @job ||= asyncable_job_klass.find(allowed_params[:id])
  end

  def set_application
    RequestStore.store[:application] = "asyncable_jobs"
  end

  def verify_access
    return true if current_user.admin?
    return true if ["Admin Intake", "Manage Claim Establishment"].any? { |role| current_user.can?(role) }

    Rails.logger.info("User with roles #{current_user.roles.join(', ')} "\
      "couldn't access #{request.original_url}")

    session["return_to"] = request.original_url
    redirect_to "/unauthorized"
  end

  def verify_job_access
    return true if current_user == job&.asyncable_user

    verify_access
  end

  def allowed_params
    params.permit(:asyncable_job_klass, :id, :page, :note, :send_to_intake_user, :job_type, :run_async)
  end

  def veteran_file_number
    request.headers["HTTP_VETERAN_FILE_NUMBER"]
  end

  def unrecognized_job
    render json: { error_code: "Unable to start unrecognized job" }, status: :unprocessable_entity
  end

  def supported_jobs
    SCHEDULED_JOBS.keys if FeatureToggle.enabled?(:async_manual_start, user: current_user) && current_user.admin?
  end
end
