##
# Task assigned to the BvaOrganization after a hearing is scheduled, created after the ScheduleHearingTask is completed.
# When the associated hearing's disposition is set, the appropriate tasks are set as children
#   (e.g., TranscriptionTask, EvidenceWindowTask, etc.).
# The task is marked complete when these children tasks are completed.
class DispositionTask < GenericTask
  before_create :check_parent_type

  class << self
    def create_disposition_task!(appeal, parent, hearing)
      disposition_task = DispositionTask.create!(
        appeal: appeal,
        parent: parent,
        assigned_to: Bva.singleton
      )

      if parent.is_a? HearingTask
        HearingTaskAssociation.create!(hearing: hearing, hearing_task: parent)
      end

      disposition_task
    end
  end

  def hearing_task
    parent
  end

  def available_actions(_user)
    [Constants.TASK_ACTIONS.POSTPONE_HEARING.to_h]
  end

  def add_schedule_hearing_task_admin_actions_data(_user)
    {
      redirect_after: "/queue/appeals/#{appeal.external_id}",
      message_detail: COPY::ADD_HEARING_ADMIN_TASK_CONFIRMATION_DETAIL,
      selected: nil,
      options: HearingAdminActionTask.subclasses.sort_by(&:label).map do |subclass|
        { value: subclass.name, label: subclass.label }
      end
    }
  end

  def update_from_params(params, user)
    disposition_params = params.delete(:business_payloads)[:values]

    if params[:status] == Constants.TASK_STATUSES.cancelled
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

    super(params, user)
  end

  def check_parent_type
    if parent.type != "HearingTask"
      fail(
        Caseflow::Error::InvalidParentTask,
        task_type: self.class.name,
        assignee_type: assigned_to.class.name
      )
    end
  end

  def reschedule(hearing_pkseq:, hearing_time:, hearing_location: nil)
    new_hearing_task = hearing_task.cancel_and_recreate

    new_hearing = slot_new_hearing(
      hearing_pkseq, hearing_time, hearing_location
    )
    self.class.create_disposition_task!(appeal, new_hearing_task, new_hearing)
  end

  def schedule_later(with_admin_action_klass: nil, instructions: nil)
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
        instructions: instructions.present? ? [instructions] : nil,
        assigned_to: HearingsManagement.singleton
      )
    end
  end

  def release() end

  def postponed(after_disposition_update:)
    hearing = hearing_task.hearing_task_association.hearing
    hearing.update(disposition: "postponed")

    case after_disposition_update[:action]
    when "reschedule"
      new_hearing_attrs = after_disposition_update[:new_hearing_attrs]
      reschedule(
        hearing_pkseq: new_hearing_attrs[:hearing_pkseq], hearing_time: new_hearing_attrs[:hearing_time],
        hearing_location: new_hearing_attrs[:hearing_location]
      )
    when "schedule_later"
      schedule_later(
        with_admin_action_klass: after_disposition_update[:with_admin_action_klass],
        instructions: after_disposition_update[:admin_action_instructions]
      )
    end
  end

  def no_show() end

  def cancelled() end

  def held() end

  private

  def slot_new_hearing(hearing_day_id, hearing_time, hearing_location)
    hearing = HearingRepository.slot_new_hearing(hearing_day_id,
                                                 appeal: appeal,
                                                 hearing_location_attrs: hearing_location&.to_hash,
                                                 scheduled_time: hearing_time&.stringify_keys)
    if appeal.is_a?(LegacyAppeal)
      AppealRepository.update_location!(appeal, LegacyAppeal::LOCATION_CODES[:caseflow])
    end

    hearing
  end
end
