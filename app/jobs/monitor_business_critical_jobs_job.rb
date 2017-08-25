# This job runs at 6pm ET and checks that mission critical jobs have started
# and completed. This will alert us if a job has not run due to
# sidekiq-cron being unreliable
class MonitorBusinessCriticalJobsJob < CaseflowJob
  queue_as :default

  BUSINESS_CRITICAL_JOBS = %w(
    CreateEstablishClaimTasksJob
    PrepareEstablishClaimTasksJob
  ).freeze

  ALERT_THRESHOLD_IN_HOURS = 5 # in hours

  MESSAGE_BASE = "Business critical job monitor results:\n".freeze

  def perform
    # Log monitoring information to both logs & slack
    Rails.logger.info(results_message)
    slack_service.send_notification(slack_message)
  end

  # build a hash of keys with their last started and completed timestamps
  def results
    @results ||= BUSINESS_CRITICAL_JOBS.reduce({}) do |hash, job_class|
      hash[job_class] = {
        started: Rails.cache.read("#{job_class}_last_started_at"),
        completed: Rails.cache.read("#{job_class}_last_completed_at")
      }
      hash
    end
  end

  private

  # Loop through results and build a general results message including
  # the last start and complete times
  def results_message
    @results_message ||= results.reduce("") do |message, (job_class, result)|
      message += "#{job_class}: Last started: #{result[:started]}. " \
             "Last completed: #{result[:completed]}\n"
      message
    end
  end

  # Loop through the results and build an error warning for jobs that specifically
  # failed to start or complete and @here the slack channel
  def failure_message
    @failure_message ||= begin
      message = results.reduce("") do |message, (job_class, result)|
        if !result[:started] || result[:started] < ALERT_THRESHOLD_IN_HOURS.hours.ago
          message += "*#{job_class} failed to start in the last #{ALERT_THRESHOLD_IN_HOURS} hours.*\n"
        end

        if !result[:completed] || result[:completed] < ALERT_THRESHOLD_IN_HOURS.hours.ago
          message += "*#{job_class} failed to complete in the last #{ALERT_THRESHOLD_IN_HOURS} hours.*\n"
        end

        message
      end

      message += "<!here>\n" if !message.length.zero?
      message
    end
  end

  def slack_message
    MESSAGE_BASE + results_message + failure_message
  end
end
