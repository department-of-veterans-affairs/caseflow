# frozen_string_literal: true

# Check for incomplete Distribution records (i.e., those with `pending` and `started` statuses)
# and try them again.
class IncompleteDistributionsJob < CaseflowJob
  queue_with_priority :high_priority
  application_attr :queue

  def perform
    restart_pending_distributions if pending_distribution_jobs.any?

    restart_stalled_distributions if stalled_distribution_jobs.any?
  end

  private

  def incomplete_distribution_jobs
    pending_distribution_jobs + stalled_distribution_jobs
  end

  def pending_distribution_jobs
    @pending_distribution_jobs ||= Distribution.pending.where("created_at < ?", 55.minutes.ago)
  end

  def restart_pending_distributions
    slack_service.send_notification("Restarting jobs for pending Distributions: #{pending_distribution_jobs.map(&:id)}")
    pending_distribution_jobs.each { |distribution| StartDistributionJob.perform_now(distribution, distribution.judge) }
  end

  def stalled_distribution_jobs
    # Found a few Distributions that took longer than 3 minutes:
    #   dss=Distribution.completed.select {|d| (d.completed_at - d.started_at)>180 rescue false};
    #   dss.map{|d| [d.id, (d.completed_at - d.started_at).round]}
    #   => [[6362, 307], [6363, 332], [6364, 318], [19040, 190], [19041, 186]]
    # About 5 minutes max. We'll go with 15 minutes to be conservative.
    @stalled_distribution_jobs ||= Distribution.started.where(started_at: nil)
      .or(Distribution.started.where("started_at < ?", 15.minutes.ago))
  end

  def restart_stalled_distributions
    slack_service.send_notification("Restarting jobs for stalled Distributions: #{stalled_distribution_jobs.map(&:id)}")
    stalled_distribution_jobs.each do |distribution|
      distribution.pending!
      distribution.distribute!
    end
  end
end
