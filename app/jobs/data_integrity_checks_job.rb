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
    PendingIncompleteAndUncancelledTaskTimersChecker
    ReviewsWithDuplicateEpErrorChecker
    StuckAppealsChecker
    UntrackedLegacyAppealsChecker
  ].freeze

  def perform
    # in case we need to access BGS e.g.
    RequestStore.store[:current_user] = User.system_user

    CHECKERS.each do |klass|
      checker_start_time = Time.zone.now
      checker = klass.constantize.new
      checker.call
      datadog_report_time_segment(segment: klass.underscore, start_time: checker_start_time)
      if checker.report?
        send_to_slack(checker)
      end
    # don't retry via normal shoryuken, just log and move to next checker.
    rescue StandardError => error
      log_error(error, { class: klass })
    end

    datadog_report_runtime(metric_group_name: "data_integrity_checks_job")
    slack_service.send_notification(
      "All checks complete",
      "DataIntegrityChecksJob",
      DataIntegrityChecker.new.slack_channel
    )
  end

  private

  def send_to_slack(checker)
    slack_service.send_notification(checker.report, checker.class.name, checker.slack_channel)
  end
end
