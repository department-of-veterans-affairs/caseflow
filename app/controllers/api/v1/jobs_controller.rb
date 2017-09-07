class Api::V1::JobsController < Api::V1::ApplicationController
  rescue_from NameError, TypeError, with: :unrecognized_job

  def start_async
    # available jobs supported by this endpoint
    @jobs = {
      "heartbeat": HeartbeatTasksJob,
      "create_establish_claim": CreateEstablishClaimTasksJob,
      "prepare_establish_claim": PrepareEstablishClaimTasksJob
    }

    # start job asynchronously as given by the job_type post param
    job_type = params.require(:job_type)
    job = @jobs[:"#{job_type}"].perform_later
    Rails.logger.info("Starting job #{job.job_id}")
    render json: { success: true, job_id: job.job_id }, status: 200
  end

  def unrecognized_job
    render json: { error_code: "Unable to start unrecognized job" }, status: 422
  end
end
