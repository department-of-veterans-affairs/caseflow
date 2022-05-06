# frozen_string_literal: true

# VSO users should not be able to convert a hearing to virtual within 11 days of the hearing.
class CancelChangeHearingRequestTypeTaskJob < CaseflowJob
  def perform
    appeal_list = find_affected_hearings
    if !appeal_list.nil?
      disable_conversion_task(appeal_list)
    end
  end

  def find_affected_hearings
    current_time = Time.zone.today
    # set the date for 10 days ahead
    deadline_time = current_time.next_day(10)
    appeal_list = []
    # find the hearing day for the deadline_time
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
    # THIS CAN PROBABLY BE MADE INTO A CONCERN. PROBABLY A STORY FOR NEXT SPRINT
    closed_tasks = 0
    appeal_list.each do |appeal|
      tasks_to_sync = appeal.tasks.open.where(
        type: [ChangeHearingRequestTypeTask.name],
        assigned_to_type: User.name
      )
      representatives = tasks_to_sync.map(&:assigned_to)
      tasks_to_sync.select { |tasks| representatives.include?(tasks.assigned_to) }.each do |task|
        task.update!(status: Constants.TASK_STATUSES.cancelled,
                     cancellation_reason: Constants.TASK_CANCELLATION_REASONS.time_deadline)
        closed_tasks += 1
      end
    end
    closed_tasks
  end
end
