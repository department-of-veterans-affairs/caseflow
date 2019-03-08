# frozen_string_literal: true

##
# Task assigned to the BvaOrganization after a hearing is scheduled, created after the ScheduleHearingTask is completed.
# When the associated hearing's disposition is set, the appropriate tasks are set as children
#   (e.g., TranscriptionTask, EvidenceWindowTask, etc.).
# The task is marked complete when these children tasks are completed.
class DispositionTask < GenericTask
  before_create :check_parent_type
  delegate :hearing, to: :hearing_task, allow_nil: true
  after_update :update_appeal_location_after_cancel, if: :task_just_canceled_and_has_legacy_appeal?
  after_update :create_ihp_tasks_after_cancel, if: :task_just_canceled_and_has_ama_appeal?

  class HearingDispositionNotCanceled < StandardError; end
  class HearingDispositionNotNoShow < StandardError; end

  class << self
    def create_disposition_task!(appeal, parent, hearing)
      disposition_task = DispositionTask.create!(
        appeal: appeal,
        parent: parent,
        assigned_to: Bva.singleton
      )

      HearingTaskAssociation.create!(hearing: hearing, hearing_task: parent)

      disposition_task
    end
  end

  def hearing_task
    @hearing_task ||= parent
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
        mark_postponed(after_disposition_update: after_disposition_update)
      when "held"
        mark_held
      when "no_show"
        mark_no_show
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

  def reschedule(hearing_day_id:, hearing_time:, hearing_location: nil)
    new_hearing_task = hearing_task.cancel_and_recreate

    new_hearing = slot_new_hearing(
      hearing_day_id, hearing_time, hearing_location
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

  private

  def mark_postponed(after_disposition_update:)
    if hearing.is_a?(LegacyHearing)
      hearing.update_caseflow_and_vacols(disposition: "postponed")
    else
      hearing.update(disposition: "postponed")
    end

    case after_disposition_update[:action]
    when "reschedule"
      new_hearing_attrs = after_disposition_update[:new_hearing_attrs]
      reschedule(
        hearing_day_id: new_hearing_attrs[:hearing_day_id], hearing_time: new_hearing_attrs[:hearing_time],
        hearing_location: new_hearing_attrs[:hearing_location]
      )
    when "schedule_later"
      schedule_later(
        with_admin_action_klass: after_disposition_update[:with_admin_action_klass],
        instructions: after_disposition_update[:admin_action_instructions]
      )
    end
  end

  def mark_cancelled() end

  def mark_held() end

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

  def cancel!
    if hearing_disposition != Constants.HEARING_DISPOSITION_TYPES.cancelled
      fail HearingDispositionNotCanceled
    end

    update!(status: Constants.TASK_STATUSES.cancelled)
  end

  def mark_no_show!
    if hearing_disposition != Constants.HEARING_DISPOSITION_TYPES.no_show
      fail HearingDispositionNotNoShow
    end

    no_show_hearing_task = NoShowHearingTask.create!(
      parent: self,
      appeal: appeal,
      assigned_to: HearingAdmin.singleton
    )

    no_show_hearing_task.update!(
      status: Constants.TASK_STATUSES.on_hold,
      on_hold_duration: 25.days
    )
  end

  private

  def task_just_canceled?
    saved_change_to_attribute?("status") && cancelled?
  end

  def task_just_canceled_and_has_legacy_appeal?
    task_just_canceled? && appeal.is_a?(LegacyAppeal)
  end

  def task_just_canceled_and_has_ama_appeal?
    task_just_canceled? && appeal.is_a?(Appeal)
  end

  def create_ihp_tasks_after_cancel
    RootTask.create_ihp_tasks!(appeal, parent)
  end

  def update_appeal_location_after_cancel
    location = if appeal.vsos.empty?
                 LegacyAppeal::LOCATION_CODES[:case_storage]
               else
                 LegacyAppeal::LOCATION_CODES[:service_organization]
               end

    AppealRepository.update_location!(appeal, location)
  end

  def hearing_disposition
    parent&.hearing_task_association&.hearing&.disposition
  end
end
