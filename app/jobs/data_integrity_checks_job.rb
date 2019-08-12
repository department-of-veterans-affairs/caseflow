# frozen_string_literal: true

class DataIntegrityChecksJob < CaseflowJob
  queue_as :low_priority
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
    SlackService.new(
      msg: checker.report,
      title: checker.class.name,
      channel: checker.slack_channel
    ).send_notification
  end
end
