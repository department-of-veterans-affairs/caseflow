class JobsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def async_start
    klass = Object.const_get params.require(:class_name)
    job = klass.perform_later
    Rails.logger.info("Starting job #{job.job_id}")
    render json: { success: true, job_id: job.job_id }, status: 200
  end
end
