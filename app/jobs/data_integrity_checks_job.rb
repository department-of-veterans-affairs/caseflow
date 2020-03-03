# frozen_string_literal: true

class DataIntegrityChecksJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :queue

  CHECKERS = %w[
    DecisionReviewTasksForInactiveAppealsChecker
    ExpiredAsyncJobsChecker
    LegacyAppealsWithNoVacolsCase
    OpenHearingTasksWithoutActiveDescendantsChecker
    OpenTasksWithClosedAtChecker
    ReviewsWithDuplicateEpErrorChecker
    StuckAppealsChecker
    UntrackedLegacyAppealsChecker
  ].freeze

  def perform
    # in case we need to access BGS e.g.
    RequestStore.store[:current_user] = User.system_user

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
