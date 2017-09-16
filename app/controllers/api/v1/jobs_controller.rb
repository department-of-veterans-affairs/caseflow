class Api::V1::JobsController < Api::V1::ApplicationController
  # available jobs supported by this endpoint
  SUPPORTED_JOBS = {
    "heartbeat" => HeartbeatTasksJob,
    "create_establish_claim" => CreateEstablishClaimTasksJob,
    "prepare_establish_claim" => PrepareEstablishClaimTasksJob,
    "reassign_old_tasks" => ReassignOldTasksJob,
    "retrieve_documents_for_reader" => RetrieveDocumentsForReaderJob,
    "dependencies_check" => DependenciesCheckJob,
    "dependencies_report_service_log" => DependenciesReportServiceLogJob,
    "out_of_service_reminder" => OutOfServiceReminderJob
  }.freeze

  def create
    # start job asynchronously as given by the job_type post param
    job = SUPPORTED_JOBS[params.require(:job_type)]
    return unrecognized_job unless job

    job = job.perform_later
    Rails.logger.info("Pushing: #{job} job_id: #{job.job_id} to queue: #{job.queue_name}")
    render json: { success: true, job_id: job.job_id }, status: 200
  end

  def unrecognized_job
    render json: { error_code: "Unable to start unrecognized job" }, status: 422
  end
end
