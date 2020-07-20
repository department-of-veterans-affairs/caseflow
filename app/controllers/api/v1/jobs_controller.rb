# frozen_string_literal: true

class Api::V1::JobsController < Api::ApplicationController
  # available jobs supported by this endpoint
  SUPPORTED_JOBS = {
    "amo_metrics_report" => AMOMetricsReportJob,
    "calculate_dispatch_stats" => CalculateDispatchStatsJob,
    "create_establish_claim" => CreateEstablishClaimTasksJob,
    "data_integrity_checks" => DataIntegrityChecksJob,
    "delete_conferences_job" => VirtualHearings::DeleteConferencesJob,
    "dependencies_check" => DependenciesCheckJob,
    "dependencies_report_service_log" => DependenciesReportServiceLogJob,
    "etl_builder" => ETLBuilderJob,
    "heartbeat" => HeartbeatTasksJob,
    "missed_job_sweeper" => MissedJobSweeperJob,
    "monthly_metrics" => MonthlyMetricsReportJob,
    "nightly_syncs" => NightlySyncsJob,
    "out_of_service_reminder" => OutOfServiceReminderJob,
    "prepare_establish_claim" => PrepareEstablishClaimTasksJob,
    "reassign_old_tasks" => ReassignOldTasksJob,
    "retrieve_documents_for_reader" => RetrieveDocumentsForReaderJob,
    "stats_collector" => StatsCollectorJob,
    "sync_intake" => SyncIntakeJob,
    "sync_reviews" => SyncReviewsJob,
    "take_docket_snapshot" => TakeDocketSnapshotJob,
    "task_timer_job" => TaskTimerJob,
    "fetch_hearing_locations_for_veterans_job" => FetchHearingLocationsForVeteransJob,
    "update_appellant_representation_job" => UpdateAppellantRepresentationJob,
    "hearing_disposition_change_job" => HearingDispositionChangeJob,
    "warm_bgs_caches_job" => WarmBgsCachesJob,
    "update_cached_appeals_attributes_job" => UpdateCachedAppealsAttributesJob
  }.freeze

  def create
    # start job asynchronously as given by the job_type post param
    job = SUPPORTED_JOBS[params.require(:job_type)]
    return unrecognized_job unless job

    job = job.perform_later
    Rails.logger.info("Pushing: #{job} job_id: #{job.job_id} to queue: #{job.queue_name}")
    render json: { success: true, job_id: job.job_id }, status: :ok
  end

  def unrecognized_job
    render json: { error_code: "Unable to start unrecognized job" }, status: :unprocessable_entity
  end
end
