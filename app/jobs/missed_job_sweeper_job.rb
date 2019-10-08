# frozen_string_literal: true

# who will watch the watcher? we will!
# periodic check that jobs we expected to run, have run.
# if not, try them again.
class MissedJobSweeperJob < CaseflowJob
  queue_with_priority :high_priority
  application_attr :queue

  def perform
    check_distribution_jobs
  end

  private

  def check_distribution_jobs
    return unless missed_distribution_jobs.any?

    slack_service.send_notification("Restarting jobs for Distributions: #{missed_distribution_jobs.map(&:id)}")
    missed_distribution_jobs.each { |distribution| StartDistributionJob.perform_now(distribution, distribution.judge) }
  end

  def missed_distribution_jobs
    @missed_distribution_jobs ||= Distribution.pending.where("created_at < ?", 55.minutes.ago)
  end
end
