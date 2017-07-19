class PrepareEstablishClaimTasksJob < ActiveJob::Base
  queue_as :default

  def perform
    count = { success: 0, fail: 0 }

    EstablishClaim.unprepared.each do |task|
      status = task.prepare_with_decision!
      count[:success] += (status == :success ? 1 : 0)
      count[:fail] += (status == :failed ? 1 : 0)
    end
    log_info(count)
  end

  def log_info(count)
    msg = "PrepareEstablishClaimTasksJob successfully ran: #{count[:success]} tasks prepared and #{count[:fail]} tasks failed"
    Rails.logger.info msg
    msg += "\n<!here>" if count[:fail] > 0
    SlackService.new(url: url).send_notification(msg)
  end

  def url
    ENV["SLACK_DISPATCH_ALERT_URL"]
  end
end
