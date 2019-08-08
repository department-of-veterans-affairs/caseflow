# frozen_string_literal: true

class Hearings::Scheduler
  attr_reader :appeal, :hearing_task

  def initialize(appeal, hearing_task: nil)
    @appeal = appeal
    @hearing_task = hearing_task
  end

  def schedule(*args)
    hearing = slot_new_hearing(*args)

    AssignHearingDispositionTask.create_assign_hearing_disposition_task!(appeal, parent, hearing)
  end

  def slot_new_hearing(hearing_day_id:, scheduled_time_string:, hearing_location_attrs: nil)
    HearingRepository.slot_new_hearing(hearing_day_id,
                                       appeal: appeal,
                                       hearing_location_attrs: hearing_location_attrs&.to_hash,
                                       scheduled_time_string: scheduled_time_string)
  end

  def reschedule(hearing_day_id:, scheduled_time_string:, hearing_location_attrs: nil)
    fail_if_hearing_task_is_nil

    new_hearing_task = hearing_task.cancel_and_recreate

    new_hearing = schedule(hearing_day_id,
                           hearing_location_attrs: hearing_location_attrs&.to_hash,
                           scheduled_time_string: scheduled_time_string)
    HearingTask.create_assign_hearing_disposition_task!(appeal, new_hearing_task, new_hearing)

    new_hearing
  end

  def reschedule_later(instructions: nil)
    fail_if_hearing_task_is_nil

    new_hearing_task = hearing_task.cancel_and_recreate

    ScheduleHearingTask.create!(
      appeal: appeal,
      instructions: instructions.present? ? [instructions] : nil,
      parent: new_hearing_task
    )
  end

  def reschedule_later_with_admin_action(instructions: nil, admin_action_klass: nil, admin_action_instructions: nil)
    schedule_task = reschedule_later(instruction: instructions)

    admin_action_klass.constantize.create!(
      appeal: appeal,
      assigned_to: HearingsManagement.singleton,
      instructions: admin_action_instructions.present? ? [admin_action_instructions] : nil,
      parent: schedule_task
    )
  end

  private

  def fail_if_hearing_task_is_nil
    if hearing_task.nil?
      fail StandardError
    end
  end
end
