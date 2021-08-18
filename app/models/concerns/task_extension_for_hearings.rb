# frozen_string_literal: true

##
# Grouping all the hearings-related task functions in a single file for
# visibility

module TaskExtensionForHearings
  extend ActiveSupport::Concern

  # Implemented in app/models.task.rb
  def ancestor_task_of_type(_task_type); end

  def available_hearing_user_actions(user)
    available_hearing_admin_actions(user) | available_hearing_mgmt_actions(user) | hearing_teams_admin_actions(user)
  end

  def most_recent_closed_hearing_task_on_appeal
    tasks = appeal.tasks.closed.order(closed_at: :desc).where(type: HearingTask.name)

    return tasks.first if appeal.is_a?(Appeal)

    # Legacy appeals can be orphaned, so find the first un-orphaned one.
    tasks.detect { |task| task.hearing&.vacols_hearing_exists? }
  end

  def create_change_hearing_disposition_task(instructions = nil)
    hearing_task = ancestor_task_of_type(HearingTask)

    if hearing_task.blank?
      fail(
        Caseflow::Error::ActionForbiddenError,
        message: COPY::REQUEST_HEARING_DISPOSITION_CHANGE_FORBIDDEN_ERROR
      )
    end

    hearing_task.create_change_hearing_disposition_task(instructions)
  end

  def create_or_update_email_recipients(hearing, recipient)
    begin
      if recipient["appellant_email"].present?
        hearing.create_or_update_recipients(
          type: AppellantHearingEmailRecipient,
          email_address: recipient["appellant_email"],
          timezone: recipient["appellant_tz"]
        )
      end

      if recipient["representative_email"].present?
        hearing.create_or_update_recipients(
          type: RepresentativeHearingEmailRecipient,
          email_address: recipient["representative_email"],
          timezone: recipient["representative_tz"]
        )
      end
    rescue ActiveRecord::RecordInvalid => error
      raise Caseflow::Error::InvalidEmailError.new(
        message: error.message,
        code: 1002
      )
    end
  end

  private

  def available_hearing_admin_actions(user)
    return [] unless HearingAdmin.singleton.user_has_access?(user)

    hearing_task = ancestor_task_of_type(HearingTask)
    return [] unless hearing_task&.open? && hearing_task&.disposition_task&.present?

    [
      Constants.TASK_ACTIONS.CREATE_CHANGE_HEARING_DISPOSITION_TASK.to_h
    ]
  end

  def available_hearing_mgmt_actions(user)
    return [] unless type == ScheduleHearingTask.name
    return [] unless HearingsManagement.singleton.user_has_access?(user)

    return [] if most_recent_closed_hearing_task_on_appeal&.hearing&.disposition.blank?

    [
      Constants.TASK_ACTIONS.CREATE_CHANGE_PREVIOUS_HEARING_DISPOSITION_TASK.to_h
    ]
  end

  def hearing_teams_admin_actions(user)
    if task_is_assigned_to_user_within_admined_hearing_organization?(user)
      return [Constants.TASK_ACTIONS.REASSIGN_TO_HEARINGS_TEAMS_MEMBER.to_h]
    end

    []
  end

  def task_is_assigned_to_user_within_admined_hearing_organization?(user)
    hearings_orgs = [HearingsManagement.singleton, HearingAdmin.singleton, TranscriptionTeam.singleton]

    assigned_to.is_a?(User) &&
      assigned_to.organizations.any? { |org| hearings_orgs.include?(org) && org.admins.include?(user) }
  end

  # used by ScheduleHearingTask and AssignHearingDispositionTask to for withdrawal of scheduled and unscheduled hearings
  def withdraw_hearing(parent)
    if appeal.is_a?(LegacyAppeal)
      AppealRepository.withdraw_hearing!(appeal)
      nil
    elsif appeal.is_a?(Appeal)
      EvidenceSubmissionWindowTask.find_or_create_by!(
        appeal: appeal,
        parent: parent,
        assigned_to: MailTeam.singleton
      )
    end
  end
end
