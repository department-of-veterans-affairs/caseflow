class HoldHearingTask < GenericTask
  class << self
    def create_hold_hearing_task!(appeal, parent, hearing)
      HoldHearingTask.create!(
        appeal: appeal,
        parent: parent,
        assigned_to: Bva.singleton
      )

      if parent.is_a? HearingTask
        HearingTaskAssociation.create!(hearing: hearing, hearing_task: parent)
      end
    end
  end

  def available_actions(user)
    if (assigned_to && assigned_to == user) || task_is_assigned_to_users_organization?(user)
      return [Constants.TASK_ACTIONS.POSTPONE_HEARING.to_h]
    end

    []
  end

  def hearing_task
    parent
  end

  def update_with_params(params, _user)
    disposition_params = params.delete(:business_payloads)[:values]
    if params[:status] == Constants.TASK_STATUSES.completed
      case disposition_params[:disposition]
      when "postponed"
        after_disposition_update = disposition_params[:after_disposition_update]
        postponed(after_disposition_update: after_disposition_update)
      when "held"
        held
      when "no_show"
        no_show
      end
    end
  end

  def reschedule(hearing_pkseq:, hearing_type:, hearing_time:, hearing_location: nil)
    new_hearing_task = hearing_task.cancel_and_recreate

    new_hearing = slot_new_hearing(
      hearing_pkseq, hearing_type, hearing_time, hearing_location
    )
    create_hold_hearing_task(appeal, new_hearing_task, new_hearing)
  end

  def schedule_later(with_admin_action_klass: nil)
    new_hearing_task = hearing_task.cancel_and_recreate

    schedule_task = ScheduleHearingTask.create!(
      parent: new_hearing_task,
      appeal: appeal,
      assigned_to: HearingsManagement.singleton
    )
    if with_admin_action_klass.present?
      with_admin_action_klass.constantize.create!(
        parent: schedule_task,
        appeal: appeal,
        assigned_to: HearingsManagement.singleton
      )
    end
  end

  def postponed(after_disposition_update:)
    hearing = hearing_task.hearing_task_association.hearing
    hearing.update(status: "postponed")

    case after_disposition_update[:action]
    when "reschedule"
      new_hearing_attrs = after_disposition_update[:new_hearing_attrs]
      reschedule(
        hearing_pkseq: new_hearing_attrs[:hearing_pkseq], hearing_type: new_hearing_attrs[:hearing_type],
        hearing_time: new_hearing_attrs[:hearing_time], hearing_location: new_hearing_attrs[:hearing_location]
      )
    when "schedule_later"
      schedule_later(with_admin_action_klass: after_disposition_update[:with_admin_action_klass])
    end
  end

  def no_show() end

  def cancelled() end

  def held() end

  private

  def slot_new_hearing(hearing_day_id, hearing_type, hearing_time, hearing_location)
    hearing = HearingRepository.slot_new_hearing(hearing_day_id,
                                                 hearing_type: (hearing_type == LegacyHearing::CO_HEARING) ? "C" : "V",
                                                 appeal: appeal,
                                                 hearing_location_attrs: hearing_location&.to_hash,
                                                 scheduled_time: hearing_time&.stringify_keys)
    if appeal.is_a?(LegacyAppeal)
      AppealRepository.update_location!(appeal, LegacyAppeal::LOCATION_CODES[:caseflow])
    end

    hearing
  end
end
