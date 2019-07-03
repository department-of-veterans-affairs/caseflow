# frozen_string_literal: true

class ExpiredAsyncJobsChecker < DataIntegrityChecker
  def call
    jobs = AsyncableJobs.new(page_size: -1).jobs.select(&:expired_without_processing?)
    job_reporter = AsyncableJobsReporter.new(jobs: jobs)
    @report << "Expired Jobs: #{jobs.count} expired unfinished asyncable jobs exist in the queue."
    @report << job_reporter.summarize
  end
end
