# frozen_string_literal: true

# who will watch the watcher? we will!
# periodic check that jobs we expected to run, have run.
# if not, try them again.
class MissedJobSweeperJob < CaseflowJob
  queue_as :high
  application_attr :queue

  def perform(_args)
    check_distribution_jobs
  end

  private

  def check_distribution_jobs
    missed_jobs = Distribution.pending.where("created_at < ?", 55.minutes.ago)
    missed_jobs.each do |distribution|
      slack_service.send_notification("Restarted Distribution job #{distribution.id}")
      StartDistributionJob.perform_now(distribution, distribution.judge)
    end
  end
end
