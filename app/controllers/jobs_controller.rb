class JobsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate

  def start_async
    # start job asynchronously as given by the job_type post param
    job_type = params.require(:job_type)
    klass = Object.const_get job_type
    job = klass.perform_later
    Rails.logger.info("Starting job #{job.job_id}")
    render json: { success: true, job_id: job.job_id }, status: 200
  rescue NameError
    Rails.logger.error("Unrecognized job #{job_type}")
    render json: { error_code: "Unable to start unrecognized job" }, status: 422
  end

  protected

  def authenticate
    # for secret http endpoints, require an auth token to be checked
    # ideally this should be using an hmac approach rather than checking
    # against a static token
    authenticate_or_request_with_http_token do |token, _options|
      return true if Rails.application.secrets.jobs_auth_token == token
      render json: { error_code: "Unauthorized to make this request" }, status: 401
    end
  end
end
