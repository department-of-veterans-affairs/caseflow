# This job is used to debug https://github.com/department-of-veterans-affairs/caseflow/issues/1814
# It is scheduled to run every 5 minute to make sure Sidekiq and Sidekiq Cron
# are both operational. It will be removed once the issue is fixed.
class HeartbeatTasksJob < ActiveJob::Base
  queue_as :low_priority

  def perform
    Rails.logger.info Sidekiq::Stats.new.inspect
  end
end
