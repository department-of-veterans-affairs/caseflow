# frozen_string_literal: true

# run once a day, overnight, to synchronize systems

class NightlySyncsJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :queue # arbitrary

  def perform
    RequestStore.store[:current_user] = User.system_user
    @slack_report = []

    sync_vacols_cases
    sync_vacols_users
    sync_decision_review_tasks
    sync_bgs_attorneys

    slack_service.send_notification(@slack_report.join("\n"), self.class.name) if @slack_report.any?
  end

  private

  def sync_vacols_users
    user_cache_start = Time.zone.now
    CachedUser.sync_from_vacols
    datadog_report_time_segment(segment: "sync_users_from_vacols", start_time: user_cache_start)
  rescue StandardError => error
    @slack_report << "*Fatal error in sync_vacols_users:* #{error}"
  end

  # rubocop:disable Metrics/MethodLength
  def sync_vacols_cases
    vacols_cases_with_error = []
    start_time = Time.zone.now
    dangling_legacy_appeals.each do |legacy_appeal|
      next if legacy_appeal.case_record.present? # extra check

      # delete pure danglers
      if any_task?(legacy_appeal)
        begin
          legacy_appeal.destroy!
        rescue ActiveRecord::InvalidForeignKey => error
          vacols_cases_with_error << legacy_appeal.id.to_s
          capture_exception(error: error, extra: { legacy_appeal_id: legacy_appeal.id })
        end
      else
        # if we have tasks and no case_record, then we need to cancel all the tasks,
        # but we do not delete the dangling LegacyAppeal record.
        legacy_appeal.tasks.open.where(parent_id: nil).each(&:cancel_task_and_child_subtasks)
        legacy_appeal.dispatch_tasks.open.each(&:invalidate!)
      end
    end
    if vacols_cases_with_error.any?
      @slack_report.unshift("VACOLS cases which cannot be deleted by sync_vacols_cases: #{vacols_cases_with_error}")
    end
    datadog_report_time_segment(segment: "sync_cases_from_vacols", start_time: start_time)
  rescue StandardError => error
    @slack_report << "*Fatal error in sync_vacols_cases:* #{error}"
  end
  # rubocop:enable Metrics/MethodLength

  # check both `Task` and `Dispatch::Task` (which doesn't inherit from `Task`)
  def any_task?(legacy_appeal)
    legacy_appeal.tasks.none? && legacy_appeal.dispatch_tasks.none?
  end

  def sync_decision_review_tasks
    # tasks that went unfinished while the case was completed should be cancelled
    checker = DecisionReviewTasksForInactiveAppealsChecker.new
    checker.call
    checker.buffer.map { |task_id| Task.find(task_id).cancelled! }
  rescue StandardError => error
    @slack_report << "*Fatal error in sync_decision_review_tasks:* #{error}"
  end

  def sync_bgs_attorneys
    start_time = Time.zone.now
    BgsAttorney.sync_bgs_attorneys
    datadog_report_time_segment(segment: "sync_bgs_attorneys", start_time: start_time)
  rescue StandardError => error
    @slack_report << "*Fatal error in sync_bgs_attorneys:* #{error}"
  end

  def dangling_legacy_appeals
    reporter = LegacyAppealsWithNoVacolsCase.new
    reporter.call
    reporter.buffer.map { |vacols_id| LegacyAppeal.find_by(vacols_id: vacols_id) }
  end
end
