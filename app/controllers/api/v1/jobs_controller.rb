# frozen_string_literal: true

class Api::V1::JobsController < Api::ApplicationController
  before_action :verify_access, only: [:create]

  def create
    # start job asynchronously as given by the job_type post param
    job = SUPPORTED_JOBS[job_params[:job_type]]
    return unrecognized_job unless job

    perform_now = job_params[:perform_now] || false
    success = true

    binding.pry

    if run_async? && !perform_now
      job = job.perform_later
      Rails.logger.info("Pushing: #{job} job_id: #{job.job_id} to queue: #{job.queue_name}")
    elsif perform_now
      job = job.perform_now
      Rails.logger.info("Starting: #{job} job_id: #{job.job_id} in queue: #{job.queue_name}")
    else
      success = false
    end

    render json: { success: success, job_id: job.job_id }, status: :ok
  end

  private

  def verify_access
    return true if current_user.admin?

    Rails.logger.info("User with roles #{current_user.roles.join(', ')} "\
      "couldn't access #{request.original_url}")

    session["return_to"] = request.original_url
    unrecognized_job
  end

  def job_params
    params.require(:job_type).permit(:perform_now)
  end

  def unrecognized_job
    render json: { error_code: "Unable to start unrecognized job" }, status: :unprocessable_entity
  end
end
