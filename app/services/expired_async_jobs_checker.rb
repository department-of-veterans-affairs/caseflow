# frozen_string_literal: true

class ExpiredAsyncJobsChecker < DataIntegrityChecker
  def call
    jobs = AsyncableJobs.new(page_size: -1).jobs.select(&:expired_without_processing?)
    job_reporter = AsyncableJobsReporter.new(jobs: jobs)
    return unless jobs.count > 0

    add_to_report "[INFO] Expired Jobs: #{jobs.count} expired unfinished asyncable jobs exist in the queue."
    add_to_report job_reporter.summarize
  end
end
