# frozen_string_literal: true

class ExpiredAsyncJobsChecker < DataIntegrityChecker
  def call
    jobs = AsyncableJobs.new(page_size: -1).jobs.select(&:expired_without_processing?)
    job_reporter = AsyncableJobsReporter.new(jobs: jobs)
    msg = "Expired Jobs: #{jobs.count} expired unfinished asyncable jobs exist in the queue.\n"
    msg += job_reporter.summarize
    Rails.logger.info msg
    report = msg
  end
end
