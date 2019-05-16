# frozen_string_literal: true

class TaskActionRepository
  class << self
    def assign_to_organization_data(task, _user = nil)
      organizations = Organization.assignable(task).map do |organization|
        {
          label: organization.name,
          value: organization.id
        }
      end

      {
        selected: nil,
        options: organizations,
        type: GenericTask.name
      }
    end

    def mail_assign_to_organization_data(_task, _user = nil)
      { options: MailTask.subclass_routing_options }
    end

    def cancel_task_data(task, _user = nil)
      {
        modal_title: COPY::CANCEL_TASK_MODAL_TITLE,
        modal_body: COPY::CANCEL_TASK_MODAL_DETAIL,
        message_title: format(COPY::CANCEL_TASK_CONFIRMATION, task.appeal.veteran_full_name),
        message_detail: format(
          COPY::MARK_TASK_COMPLETE_CONFIRMATION_DETAIL,
          task.assigned_by&.full_name || "the assigner"
        )
      }
    end

    def assign_to_user_data(task, user = nil)
      users = if task.assigned_to.is_a?(Organization)
                task.assigned_to.users
              elsif task.parent&.assigned_to.is_a?(Organization)
                task.parent.assigned_to.users.reject { |check_user| check_user == task.assigned_to }
              else
                []
              end

      extras = if task.is_a?(HearingAdminActionTask)
                 {
                   redirect_after: "/organizations/#{HearingAdmin.singleton.url}",
                   message_detail: COPY::HEARING_ASSIGN_TASK_SUCCESS_MESSAGE_DETAIL
                 }
               else
                 {}
               end

      {
        selected: user,
        options: users_to_options(users),
        type: task.type
      }.merge(extras)
    end

    def assign_to_judge_data(task, _user = nil)
      {
        selected: task.root_task.children.find { |child| child.is_a?(JudgeTask) }&.assigned_to,
        options: users_to_options(Judge.list_all),
        type: JudgeQualityReviewTask.name
      }
    end

    def assign_to_attorney_data(task, _user = nil)
      {
        selected: nil,
        options: nil,
        type: task.is_a?(LegacyTask) ? AttorneyLegacyTask.name : AttorneyTask.name
      }
    end

    def assign_to_privacy_team_data(_task, _user = nil)
      org = PrivacyTeam.singleton

      {
        selected: org,
        options: [{ label: org.name, value: org.id }],
        type: PrivacyActTask.name
      }
    end

    def assign_to_translation_team_data(_task, _user = nil)
      org = Translation.singleton

      {
        selected: org,
        options: [{ label: org.name, value: org.id }],
        type: TranslationTask.name
      }
    end

    def add_admin_action_data(task, user = nil)
      if task.is_a? ScheduleHearingTask
        schedule_hearing_task_add_admin_action_data(task, user)
      else
        legacy_and_colocated_task_add_admin_action_data(task, user)
      end
    end

    def schedule_hearing_task_add_admin_action_data(task, _user)
      {
        redirect_after: "/queue/appeals/#{task.appeal.external_id}",
        message_detail: COPY::ADD_HEARING_ADMIN_TASK_CONFIRMATION_DETAIL,
        selected: nil,
        options: HearingAdminActionTask.subclasses.sort_by(&:label).map do |subclass|
          { value: subclass.name, label: subclass.label }
        end
      }
    end

    def legacy_and_colocated_task_add_admin_action_data(_task, _user)
      {
        redirect_after: "/queue",
        selected: nil,
        options: Constants::CO_LOCATED_ADMIN_ACTIONS.map do |key, value|
          {
            label: value,
            value: key
          }
        end,
        type: ColocatedTask.name
      }
    end

    def change_task_type_data(task, user = nil)
      if task.is_a? MailTask
        mail_assign_to_organization_data(task, user)
      else
        legacy_and_colocated_task_add_admin_action_data(task, user)
      end
    end

    def complete_data(task, _user = nil)
      if task.is_a? NoShowHearingTask
        {
          modal_body: COPY::NO_SHOW_HEARING_TASK_COMPLETE_MODAL_BODY
        }
      elsif task.is_a? HearingAdminActionTask
        {
          modal_body: COPY::HEARING_SCHEDULE_COMPLETE_ADMIN_MODAL
        }
      else
        {
          modal_body: COPY::MARK_TASK_COMPLETE_COPY
        }
      end
    end

    def schedule_veteran_data(_task, _user = nil)
      {
        selected: nil,
        options: nil,
        type: ScheduleHearingTask.name
      }
    end

    def return_to_attorney_data(task, _user = nil)
      assignee = task.children.select { |child| child.is_a?(AttorneyTask) }.max_by(&:created_at)&.assigned_to
      attorneys = JudgeTeam.for_judge(task.assigned_to)&.attorneys || []
      attorneys |= [assignee] if assignee.present?
      {
        selected: assignee,
        options: users_to_options(attorneys),
        type: AttorneyRewriteTask.name
      }
    end

    def complete_transcription_data(_task, _user)
      {
        modal_body: COPY::COMPLETE_TRANSCRIPTION_BODY
      }
    end

    def assign_to_hearing_schedule_team_data(task, _user)
      {
        redirect_after: "/queue/appeals/#{task.appeal.external_id}",
        modal_title: COPY::RETURN_CASE_TO_HEARINGS_MANAGEMENT_TITLE,
        modal_body: COPY::RETURN_CASE_TO_HEARINGS_MANAGEMENT_BODY,
        message_title: format(COPY::RETURN_CASE_TO_HEARINGS_MANAGEMENT_MESSAGE_TITLE, task.appeal.veteran_full_name),
        message_detail: format(COPY::RETURN_CASE_TO_HEARINGS_MANAGEMENT_MESSAGE_BODY, task.appeal.veteran_full_name)
      }
    end

    def withdraw_hearing_data(task, _user)
      {
        redirect_after: "/queue/appeals/#{task.appeal.external_id}",
        modal_title: COPY::WITHDRAW_HEARING_MODAL_TITLE,
        modal_body: COPY::WITHDRAW_HEARING_MODAL_BODY,
        message_title: format(COPY::WITHDRAW_HEARING_SUCCESS_MESSAGE_TITLE, task.appeal.veteran_full_name),
        message_detail: format(COPY::WITHDRAW_HEARING_SUCCESS_MESSAGE_BODY, task.appeal.veteran_full_name),
        back_to_hearing_schedule: true
      }
    end

    def add_schedule_hearing_task_admin_actions_data(task, _user)
      {
        redirect_after: "/queue/appeals/#{task.appeal.external_id}",
        message_detail: COPY::ADD_HEARING_ADMIN_TASK_CONFIRMATION_DETAIL,
        selected: nil,
        options: HearingAdminActionTask.subclasses.sort_by(&:label).map do |subclass|
          { value: subclass.name, label: subclass.label }
        end
      }
    end

    private

    def users_to_options(users)
      users.map do |user|
        {
          label: user.full_name,
          value: user.id
        }
      end
    end
  end
end
