# frozen_string_literal: true

class StuckAppealsChecker < DataIntegrityChecker
  def slack_channel
    "#appeals-echo"
  end

  def call
    return if stuck_appeals.count == 0 && appeals_maybe_not_closed.count == 0

    add_to_report "To resolve, see https://github.com/department-of-veterans-affairs/caseflow/wiki/Resolving-Background-Job-Alerts#stuckappealschecker\n"

    build_report_no_active_task
    add_to_report ""
    build_report_closed_root_open_children
  end

  ACCEPTABLE_POST_DISPATCH_TASKS ||= [
    TrackVeteranTask.name, # https://dsva.slack.com/archives/C01DFC41BPV/p1634756194393000?thread_ts=1633042678.442600&cid=C01DFC41BPV
    BoardGrantEffectuationTask.name, # A post-dispatch task
    *MailTask.descendants.map(&:name) # Mail can arrive after appeal is dispatched
  ].freeze

  private

  def build_report_no_active_task
    add_to_report "AppealsWithNoTasksOrAllTasksOnHoldQuery: #{stuck_appeals.count}"
    add_to_report "  Appeal ids: #{stuck_appeals.pluck(:id).sort}"
  end

  def build_report_closed_root_open_children
    add_to_report "AppealsWithClosedRootTaskOpenChildrenQuery: #{appeals_maybe_not_closed.count}"
    non_acceptable_tasks = appeals_maybe_not_closed_query.active_tasks.where.not(type: ACCEPTABLE_POST_DISPATCH_TASKS)
    add_to_report "  ignoring MailTask, TrackVeteranTask, BoardGrantEffectuationTask: #{non_acceptable_tasks.count}"
    add_to_report non_acceptable_tasks.group(:type).count.to_s.tr(",", "\n")
  end

  def appeals_maybe_not_closed_query
    @appeals_maybe_not_closed_query ||= AppealsWithClosedRootTaskOpenChildrenQuery.new
  end

  def appeals_maybe_not_closed
    @appeals_maybe_not_closed ||= appeals_maybe_not_closed_query.call
  end

  def stuck_appeals
    @stuck_appeals ||= AppealsWithNoTasksOrAllTasksOnHoldQuery.new.call
  end
end
