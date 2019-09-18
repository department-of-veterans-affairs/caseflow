# frozen_string_literal: true

class DataIntegrityChecksJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :queue

  CHECKERS = %w[
    ExpiredAsyncJobsChecker
    OpenHearingTasksWithoutActiveDescendantsChecker
    UntrackedLegacyAppealsChecker
  ].freeze

  def perform
    CHECKERS.each do |klass|
      checker = klass.constantize.new
      checker.call
      if checker.report?
        send_to_slack(checker)
      end
    end
  end

  private

  def send_to_slack(checker)
    slack = SlackService.new(url: ENV["SLACK_DISPATCH_ALERT_URL"])
    slack.send_notification(checker.report, checker.class.name, checker.slack_channel)
  end
end
