# frozen_string_literal: true

##
# Task to serve as interface with shared methods for the following hearings mail tasks:
#   - HearingPostponementRequestMailTask
#   - HearingWithdrawalRequestMailTask
# HearingRequestMailTask is itself not an assignable task type
##
class HearingRequestMailTask < MailTask
  include RunAsyncable
  validates :parent, presence: true, on: :create

  before_validation :verify_request_type_designated

  class HearingAssociationMissing < StandardError
    def initialize
      super(format(COPY::HEARING_TASK_ASSOCIATION_MISSING_MESSAGE, hearing_task_id))
    end
  end

  class << self
    def allow_creation?(*)
      false
    end

    # All descendant postponement/withdrawal tasks will initially be assigned to the Hearing Admin org
    def default_assignee(_task)
      HearingAdmin.singleton
    end
  end

  def available_actions(_user)
    []
  end

  def recent_hearing
    if appeal.is_a?(LegacyAppeal)
      appeal.hearings.max_by(&:created_at)
    else
      appeal.hearings.order(created_at: :desc).first
    end
  end

  def hearing_task
    appeal.tasks.open.where(type: HearingTask.name).order(assigned_at: :desc).first
  end

  def update_from_params(params, current_user)
    payload_values = params.delete(:business_payloads)&.dig(:values)
    if params[:status] == Constants.TASK_STATUSES.cancelled && payload_values[:disposition].present?
      created_tasks = update_hearing_and_tasks(params: params, payload_values: payload_values)
      [self] + created_tasks
    else
      super(payload_values, current_user)
    end
  end

  private

  # Ensure create is called on a descendant mail task and not directly on the HearingRequestMailTask class
  def verify_request_type_designated
    if self.class == HearingRequestMailTask
      fail Caseflow::Error::InvalidTaskTypeOnTaskCreate, task_type: type
    end
  end

  def update_hearing_and_tasks(params:, payload_values:)
    created_tasks = case payload_values[:disposition]
                    when Constants.HEARING_DISPOSITION_TYPES.postponed
                      mark_hearing_with_disposition(
                        payload_values: payload_values,
                        instructions: params["instructions"]
                      )
                    else
                      fail ArgumentError, "unknown disposition"
                    end
    update_with_instructions(instructions: params[:instructions]) if params[:instructions].present?

    created_tasks || []
  end

  def mark_hearing_with_disposition(payload_values:, instructions: nil)
    multi_transaction do
      if recent_hearing
        if payload_values[:disposition] == Constants.HEARING_DISPOSITION_TYPES.postponed
          update_hearing(disposition: Constants.HEARING_DISPOSITION_TYPES.postponed)
        end

        clean_up_virtual_hearing
      end
      mark_task_as_completed
      reschedule_or_schedule_later(
        instructions: instructions,
        after_disposition_update: payload_values[:after_disposition_update]
      )
    end
  end

  def update_hearing(hearing_hash)
    hearing = recent_hearing
    fail HearingAssociationMissing, hearing_task&.id if hearing.nil?

    if hearing.is_a?(LegacyHearing)
      hearing.update_caseflow_and_vacols(hearing_hash)
    else
      hearing.update(hearing_hash)
    end
  end

  def reschedule_or_schedule_later(instructions: nil, after_disposition_update:)
    case after_disposition_update[:action]
    when "reschedule"
      new_hearing_attrs = after_disposition_update[:new_hearing_attrs]
      reschedule(
        hearing_day_id: new_hearing_attrs[:hearing_day_id],
        scheduled_time_string: new_hearing_attrs[:scheduled_time_string],
        hearing_location: new_hearing_attrs[:hearing_location],
        virtual_hearing_attributes: new_hearing_attrs[:virtual_hearing_attributes],
        notes: new_hearing_attrs[:notes],
        email_recipients_attributes: new_hearing_attrs[:email_recipients]
      )
    else
      fail ArgumentError, "unknown disposition action"
    end
  end

  def reschedule(
    hearing_day_id:,
    scheduled_time_string:,
    hearing_location: nil,
    virtual_hearing_attributes: nil,
    notes: nil,
    email_recipients_attributes: nil
  )
    multi_transaction do
      new_hearing_task = hearing_task.cancel_and_recreate

      new_hearing = HearingRepository.slot_new_hearing(hearing_day_id: hearing_day_id,
                                                       appeal: appeal,
                                                       hearing_location_attrs: hearing_location&.to_hash,
                                                       scheduled_time_string: scheduled_time_string,
                                                       notes: notes)
      if virtual_hearing_attributes.present?
        @alerts = VirtualHearings::ConvertToVirtualHearingService
          .convert_hearing_to_virtual(new_hearing, virtual_hearing_attributes)
      elsif email_recipients_attributes.present?
        create_or_update_email_recipients(new_hearing, email_recipients_attributes)
      end

      disposition_task = AssignHearingDispositionTask
        .create_assign_hearing_disposition_task!(appeal, new_hearing_task, new_hearing)

      [new_hearing_task, disposition_task]
    end
  end

  def clean_up_virtual_hearing
    if recent_hearing.virtual?
      perform_later_or_now(VirtualHearings::DeleteConferencesJob)
    end
  end

  def mark_task_as_completed
    update!(status: Constants.TASK_STATUSES.completed)
  end
end
