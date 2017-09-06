class JobsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :verify_authentication_token

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
  rescue NameError, TypeError
    Rails.logger.error("Unrecognized job #{job_type}")
    render json: { error_code: "Unable to start unrecognized job" }, status: 422
  end

  protected

  def verify_authentication_token
    # TODO: should we limit access to only lambda API clients?
    return unauthorized unless api_key

    Rails.logger.info("API authenticated by #{api_key.consumer_name}")
  end

  def api_key
    # Check if the provided token matches with our API
    @api_key ||= authenticate_with_http_token { |token, _options| ApiKey.authorize(token) }
  end

  def unauthorized
    render json: { status: "unauthorized" }, status: 401
  end
end
