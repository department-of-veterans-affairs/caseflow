# frozen_string_literal: true

##
# Task to process a hearing withdrawal request received via the mail
#
# When this task is created:
#   - It's parent task is set as the RootTask of the associated appeal
#   - The task is assigned to the MailTeam to track where the request originated
#   - A child task of the same name is created and assigned to the HearingAdmin organization
##
class HearingWithdrawalRequestMailTask < HearingRequestMailTask
  prepend HearingWithdrawn

  class << self
    def label
      COPY::HEARING_WITHDRAWAL_REQUEST_MAIL_TASK_LABEL
    end

    def allow_creation?(*)
      true
    end
  end

  TASK_ACTIONS = [
    Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h,
    Constants.TASK_ACTIONS.COMPLETE_AND_WITHDRAW.to_h,
    Constants.TASK_ACTIONS.ASSIGN_TO_TEAM.to_h,
    Constants.TASK_ACTIONS.ASSIGN_TO_PERSON.to_h,
    Constants.TASK_ACTIONS.CANCEL_TASK.to_h
  ].freeze

  # Purpose: Determines the actions a user can take depending on their permissions and the state of the appeal
  # Params: user - The current user object
  # Return: The task actions array of objects
  def available_actions(user)
    return [] unless user.in_hearing_admin_team?

    if active_schedule_hearing_task || hearing_scheduled_and_awaiting_disposition?
      TASK_ACTIONS
    else
      [
        Constants.TASK_ACTIONS.CHANGE_TASK_TYPE.to_h,
        Constants.TASK_ACTIONS.CANCEL_TASK.to_h
      ]
    end
  end

  def update_from_params(params, user)
    if params[:status] == Constants.TASK_STATUSES.completed
      created_tasks = update_hearing_and_cancel_tasks
      update_self_and_parent_mail_task(user: user, admin_context: params[:instructions])

      [self] + (created_tasks || [])
    else
      super(params, user)
    end
  end

  private

  def update_hearing_and_cancel_tasks
    multi_transaction do
      maybe_evidence_task = withdraw_hearing(hearing_task.parent)
      cancel_active_hearing_tasks
      # Must cancel tasks first, otherwise hearing_task returns nil
      mark_hearing_cancelled if open_hearing

      [maybe_evidence_task].compact
    end
  end

  def mark_hearing_cancelled
    multi_transaction do
      update_hearing(disposition: Constants.HEARING_DISPOSITION_TYPES.cancelled)
      clean_up_virtual_hearing
    end
  end

  def cancel_active_hearing_tasks
    hearing_task.cancel_task_and_child_subtasks
    cancel_hearing_related_mail_tasks
  end

  def cancel_hearing_related_mail_tasks
    return if hearing_related_mail_tasks.empty?

    hearing_related_mail_tasks.update_all(status: Constants.TASK_STATUSES.cancelled)
  end

  def hearing_related_mail_tasks
    appeal.tasks.where(type: HearingRelatedMailTask.name)&.active
  end

  def update_self_and_parent_mail_task(user:, admin_context:)
    updated_instructions = format_instructions_on_completion(admin_context)

    super(user: user, instructions: updated_instructions)
  end

  def format_instructions_on_completion(admin_context)
    markdown_to_append = <<~EOS

      ***

      ###### Mark as complete and withdraw hearing:

      **DETAILS**
      #{admin_context}
    EOS

    [instructions[0] + markdown_to_append]
  end
end
