class JobsController < ApplicationController
  skip_before_action :verify_authenticity_token
  before_action :authenticate

  def start_async
    # start job asynchronously as given by the class_name post param
    klass = Object.const_get params.require(:class_name)
    job = klass.perform_later
    Rails.logger.info("Starting job #{job.job_id}")
    render json: { success: true, job_id: job.job_id }, status: 200
  end

  protected
  def authenticate
    # for secret http endpoints, require an auth token to be checked
    # ideally this should be using an hmac approach rather than checking
    # against a static token
    authenticate_or_request_with_http_token do |token, options|
      return true if Rails.application.secrets.jobs_auth_token == token
      render json: { error_code: "Unauthorized to make this request" }, status: 401
    end
  end
end
