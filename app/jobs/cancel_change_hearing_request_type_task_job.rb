# frozen_string_literal: true

# VSO users should not be able to convert a hearing to virtual within 11 days of the hearing.
class CancelChangeHearingRequestTypeTaskJob < CaseflowJob
  queue_with_priority :low_priority
  application_attr :dispatch

  def perform
    # find appeals that have hearings within 11 days of scheduled time
    appeal_list = find_affected_hearings
    # if there are appeals that fit the criteria, cancel the tasks
    if !appeal_list.nil?
      disable_conversion_task(appeal_list)
    end
  end

  def find_affected_hearings
    current_time = Time.zone.today
    # set the date for 10 days ahead
    deadline_time = current_time.next_day(10)
    appeal_list = []
    # find the hearing day(daily docket) for the deadline_time
    hearing_day = HearingDay.find_by(scheduled_for: deadline_time)
    if hearing_day.nil?
      return
    end

    # iterate through hearings on the hearing day to find appeal
    Hearing.where(hearing_day_id: hearing_day.id).to_a.each do |hearing|
      appeal = Appeal.find_by(id: hearing.appeal_id)
      appeal_list.push(appeal)
    end
    appeal_list
  end

  def disable_conversion_task(appeal_list)
    closed_tasks = 0
    # iterate through appeals to find open ChangeHearingRequestTypeTasks
    appeal_list.each do |appeal|
      tasks_to_cancel = appeal.tasks.open.where(
        type: [ChangeHearingRequestTypeTask.name],
        assigned_to_type: User.name
      )
      # get array of VSO users on the appeal that are assigned ChangeHearingRequestTypeTasks
      representatives = tasks_to_cancel.map(&:assigned_to).select { |user| user.roles.include?("VSO") }
      # cancel the tasks
      tasks_to_cancel.select { |tasks| representatives.include?(tasks.assigned_to) }.each do |task|
        task.update!(status: Constants.TASK_STATUSES.cancelled)
        closed_tasks += 1
      end
    end
    closed_tasks
  end
end
