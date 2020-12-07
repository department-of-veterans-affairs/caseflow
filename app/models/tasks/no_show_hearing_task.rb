# frozen_string_literal: true

##
# Task created after an appellant no-shows for a hearing. Gives the hearings team the options to decide how to handle
# the no-show hearing after the judge indicates that the appellant no-showed.
#
# Task is created as a child of AssignHearingDispositionTask with a TimedHoldTask which is set to expire after
# DAYS_ON_HOLD days. Before the task expires, users can manually complete this task, postpone hearing, or create a
# ChangeHearingDispositionTask.
#
# If DAYS_ON_HOLD as passed, TaskTimerJob cleans up the TimedHoldTask and automatically completes NoShowHearingTask.
#
# Completion/cancellation of  NoShowHearingTaskcan trigger closing of parent AssignHearingDispositionTask and
# if AssignHearingDispositionTask was the last open task of grandparent HearingTask, either of the following can happen:
#  - If appeal is AMA, create an EvidenceSubmissionWindowTask as child of HearingTask OR
#  - If appeal is Legacy, route location according to logic in HearingTask#update_legacy_appeal_location
##
class NoShowHearingTask < Task
  before_validation :set_assignee

  DAYS_ON_HOLD = 15

  def self.create_with_hold(parent_task)
    multi_transaction do
      create!(parent: parent_task, appeal: parent_task.appeal).tap do |no_show_hearing_task|
        TimedHoldTask.create_from_parent(
          no_show_hearing_task,
          days_on_hold: DAYS_ON_HOLD,
          instructions: ["Mail must be received within 14 days of the original hearing date."]
        )
      end
    end
  end

  def available_actions(user)
    hearing_admin_actions = available_hearing_user_actions(user)

    if (assigned_to &.== user) || task_is_assigned_to_users_organization?(user)
      [
        Constants.TASK_ACTIONS.RESCHEDULE_NO_SHOW_HEARING.to_h,
        Constants.TASK_ACTIONS.MARK_NO_SHOW_HEARING_COMPLETE.to_h,
        Constants.TASK_ACTIONS.CREATE_CHANGE_HEARING_DISPOSITION_TASK.to_h
      ] | hearing_admin_actions
    else
      hearing_admin_actions
    end
  end

  # overriding to allow action on an on_hold task
  def actions_available?(user)
    actions_allowable?(user)
  end

  def reschedule_hearing
    multi_transaction do
      # NOTE: the order of the next two lines is important because if we run the 2nd line first,
      # the logic in HearingTask#when_child_task_completed will execute eventhough we mean to
      # create another ScheduleHearingTask

      # Attach the new task to the same parent as the previous HearingTask.
      ScheduleHearingTask.create!(appeal: appeal, parent: ancestor_task_of_type(HearingTask)&.parent)

      update!(status: Constants.TASK_STATUSES.completed)
    end
  end

  private

  # ensures this task gets completed when child TimedHoldTask is completed after 30 days
  def cascade_closure_from_child_task?(child_task)
    return true if child_task&.type == TimedHoldTask.name

    super
  end

  def set_assignee
    self.assigned_to ||= HearingsManagement.singleton
  end
end
