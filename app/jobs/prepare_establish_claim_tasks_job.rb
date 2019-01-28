class PrepareEstablishClaimTasksJob < ApplicationJob
  queue_as :low_priority
  application_attr :dispatch

  def perform
    RequestStore.store[:current_user] = User.system_user

    prepare_establish_claims
    count_unfinished_jobs
  end

  def prepare_establish_claims
    count = { success: 0, fail: 0 }

    # Set user to system_user to avoid sensitivity errors
    RequestStore.store[:current_user] = User.system_user

    EstablishClaim.unprepared.each do |task|
      status = task.prepare_with_decision!
      count[:success] += ((status == :success) ? 1 : 0)
      count[:fail] += ((status == :failed) ? 1 : 0)
    end
    log_info(count)
  end

  def count_unfinished_jobs
    jobs = AsyncableJobs.new.jobs
    msg = "Jobs: #{jobs.count} unfinished asyncable jobs exist in the queue"
    Rails.logger.info msg
    SlackService.new(url: url).send_notification(msg)
  end

  def log_info(count)
    msg = "PrepareEstablishClaimTasksJob successfully ran: #{count[:success]} tasks " \
          "prepared and #{count[:fail]} tasks failed"
    Rails.logger.info msg
    msg += "\n<!here>" if count[:fail] > 0
    SlackService.new(url: url).send_notification(msg)
  end

  def url
    ENV["SLACK_DISPATCH_ALERT_URL"]
  end
end
