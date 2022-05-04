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
    deadline_time = current_time.next_day(11)
    appeal_list = []
    hearing_day = HearingDay.find_by(scheduled_for: deadline_time)
    byebug
    if hearing_day.nil?
      return
    end

    # iterate through hearings on the hearing day to find appeal
    Hearing.where(hearing_day_id: hearing_day.id).to_a.each do |hearing|
      appeal = Appeal.find_by(hearing_id: hearing.id)
      appeal_list.push(appeal)
    end
  end

  def disable_conversion_task(appeal_list)
    # Since the changehearingrequesttypetask is tied to the appeal, I'm not sure about what to do for postponed hearings
    # Another job to check all hearings over 11 days away? That would be so inefficient
    # Would need to look into how a hearing is rescheduled.
    # If it's simply a matter of updating :scheduled_time, then maybe a new changehearingrequesttypetask can be created at the same time.
    # Why would a hearing be rescheduled?
    appeal_list.each do |appeal|
      tasks_to_sync = appeal.tasks.open.where(
        type: [ChangeHearingRequestTypeTask.name],
        assigned_to_type: Organization.name
      )
      representatives = tasks_to_sync.map(&:assigned_to)
      tasks_to_sync.select { |tasks| representatives.include?(tasks.assigned_to) }.each do |task|
        task.update!(status: Constants.TASK_STATUSES.cancelled,
                     cancellation_reason: Constants.TASK_CANCELLATION_REASONS.time_deadline)
        # DO CHILD TASKS NEED TO BE CANCELLED TOO??????????????/
      end
    end
  end
end
