# frozen_string_literal: true

# run once a day, overnight, to synchronize systems

class NightlySyncsJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :queue # arbitrary

  def perform
    RequestStore.store[:current_user] = User.system_user

    sync_vacols_users
    sync_vacols_cases
    sync_decision_review_tasks
    sync_bgs_attorneys
  end

  private

  def sync_vacols_users
    user_cache_start = Time.zone.now
    CachedUser.sync_from_vacols
    datadog_report_time_segment(segment: "sync_users_from_vacols", start_time: user_cache_start)
  end

  def sync_vacols_cases
    start_time = Time.zone.now
    dangling_legacy_appeals.each do |legacy_appeal|
      next if legacy_appeal.case_record.present? # extra check

      # delete pure danglers
      if legacy_appeal.tasks.none?
        legacy_appeal.destroy!
      else
        # if we have tasks and no case_record, then we need to cancel all the tasks,
        # but we do not delete the dangling LegacyAppeal record.
        legacy_appeal.tasks.open.where(parent_id: nil).each(&:cancel_task_and_child_subtasks)
      end
    end
    datadog_report_time_segment(segment: "sync_cases_from_vacols", start_time: start_time)
  end

  def sync_decision_review_tasks
    # tasks that went unfinished while the case was completed should be cancelled
    checker = DecisionReviewTasksForInactiveAppealsChecker.new
    checker.call
    checker.buffer.map { |task_id| Task.find(task_id).cancelled! }
  end

  def sync_bgs_attorneys
    start_time = Time.zone.now
    BgsAttorney.sync_bgs_attorneys
    datadog_report_time_segment(segment: "sync_bgs_attorneys", start_time: start_time)
  end

  def dangling_legacy_appeals
    reporter = LegacyAppealsWithNoVacolsCase.new
    reporter.call
    reporter.buffer.map { |vacols_id| LegacyAppeal.find_by(vacols_id: vacols_id) }
  end
end
