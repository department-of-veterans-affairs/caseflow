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
        type: task.type
      }
    end

    def mail_assign_to_organization_data(_task, _user = nil)
      { options: MailTask.subclass_routing_options }
    end

    def cancel_task_data(task, _user = nil)
      assigner_name = task.assigned_by&.full_name || "the assigner"
      {
        modal_title: COPY::CANCEL_TASK_MODAL_TITLE,
        modal_body: format(COPY::CANCEL_TASK_MODAL_DETAIL, assigner_name),
        message_title: format(COPY::CANCEL_TASK_CONFIRMATION, task.appeal.veteran_full_name),
        message_detail: format(COPY::MARK_TASK_COMPLETE_CONFIRMATION_DETAIL, assigner_name)
      }
    end

    def cancel_address_verify_task_and_assign_regional_office_data(_task, _user = nil)
      {
        modal_title: COPY::CANCEL_ADDRESS_VERIFY_TASK_AND_ASSIGN_REGIONAL_OFFICE_MODAL_TITLE,
        modal_body: COPY::CANCEL_ADDRESS_VERIFY_TASK_AND_ASSIGN_REGIONAL_OFFICE_MODAL_DETAIL,
        message_title: COPY::CANCEL_ADDRESS_VERIFY_TASK_AND_ASSIGN_REGIONAL_OFFICE_MODAL_UPDATED_SUCCESS_TITLE,
        message_detail: COPY::CANCEL_ADDRESS_VERIFY_TASK_AND_ASSIGN_REGIONAL_OFFICE_MODAL_UPDATED_SUCCESS_DETAIL
      }
    end

    def cancel_foreign_veterans_case_data(task, _user = nil)
      {
        modal_title: COPY::CANCEL_FOREIGN_VETERANS_CASE_TASK_MODAL_TITLE,
        modal_body: COPY::CANCEL_FOREIGN_VETERANS_CASE_TASK_MODAL_DETAIL,
        message_title: format(COPY::CANCEL_TASK_CONFIRMATION, task.appeal.veteran_full_name),
        message_detail: format(
          COPY::MARK_TASK_COMPLETE_CONFIRMATION_DETAIL,
          task.assigned_by&.full_name || "the assigner"
        )
      }
    end

    def send_to_schedule_veterans_list(task, _user = nil)
      {
        modal_title: COPY::SEND_TO_SCHEDULE_VETERAN_LIST_MODAL_TITLE,
        modal_body: COPY::SEND_TO_SCHEDULE_VETERAN_LIST_MODAL_DETAIL,
        message_title: COPY::SEND_TO_SCHEDULE_VETERAN_LIST_MESSAGE_TITLE,
        message_detail: format(
          COPY::SEND_TO_SCHEDULE_VETERAN_LIST_MESSAGE_DETAIL,
          task.appeal.veteran_full_name
        )
      }
    end

    def assign_to_user_data(task, user = nil)
      users = potential_task_assignees(task)

      extras = if task.is_a?(HearingAdminActionTask)
                 {
                   redirect_after: "/organizations/#{HearingsManagement.singleton.url}",
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

    def qr_return_to_judge_data(task, _user = nil)
      {
        selected: task.root_task.children.find { |child| child.is_a?(JudgeTask) }&.assigned_to,
        options: users_to_options(Judge.list_all),
        type: JudgeQualityReviewTask.name
      }
    end

    def reassign_to_judge_data(task, _user = nil)
      {
        selected: nil,
        options: users_to_options(Judge.list_all),
        type: task.appeal_type.eql?(Appeal.name) ? task.type : "JudgeLegacyAssignTask"
      }
    end

    def dispatch_return_to_judge_data(task, _user = nil)
      {
        selected: task.root_task.children.find { |child| child.is_a?(JudgeTask) }&.assigned_to,
        options: users_to_options(Judge.list_all),
        type: JudgeDispatchReturnTask.name
      }
    end

    def judge_dispatch_return_to_attorney_data(task, _user = nil)
      attorney = task.appeal.assigned_attorney
      {
        selected: attorney,
        options: users_to_options([JudgeTeam.for_judge(task.assigned_to)&.attorneys, attorney].flatten.compact),
        type: AttorneyDispatchReturnTask.name
      }
    end

    def assign_to_attorney_data(task, _user = nil)
      {
        selected: nil,
        options: nil,
        type: task.is_a?(LegacyTask) ? AttorneyLegacyTask.name : AttorneyTask.name
      }
    end

    def judge_qr_return_to_attorney_data(task, _user = nil)
      attorney = task.appeal.assigned_attorney
      {
        selected: attorney,
        options: users_to_options([JudgeTeam.for_judge(task.assigned_to)&.attorneys, attorney].flatten.compact),
        type: AttorneyQualityReviewTask.name
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

    def send_motion_to_vacate_to_judge_data(task, _user = nil)
      {
        selected: task.root_task.children.find { |child| child.is_a?(JudgeTask) }&.assigned_to,
        options: users_to_options(Judge.list_all),
        type: JudgeAddressMotionToVacateTask.name
      }
    end

    def address_motion_to_vacate_data(task, _user = nil)
      attorney = task.appeal.assigned_attorney
      {
        selected: attorney,
        options: users_to_options([JudgeTeam.for_judge(task.assigned_to)&.attorneys, attorney].flatten.compact.uniq),
        type: PostDecisionMotion.name
      }
    end

    def sign_motion_to_vacate_data(_task, _user = nil)
      {}
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
            value: ColocatedTask.find_subclass_by_action(key).name
          }
        end
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
      params = {}
      params[:modal_body] = if task.is_a? NoShowHearingTask
                              COPY::NO_SHOW_HEARING_TASK_COMPLETE_MODAL_BODY
                            elsif task.is_a? HearingAdminActionTask
                              COPY::HEARING_SCHEDULE_COMPLETE_ADMIN_MODAL
                            else
                              COPY::MARK_TASK_COMPLETE_COPY
                            end

      if defined? task.completion_contact
        params[:contact] = task.completion_contact
      end

      params
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

      judge_team = JudgeTeam.for_judge(task.assigned_to)

      # Include attorneys for all judge teams in list of possible recipients so that judges can send cases to
      # attorneys who are not on their judge team.
      attorneys = (judge_team&.attorneys || []) + JudgeTeam.where.not(id: judge_team&.id).map(&:attorneys).flatten
      attorneys |= [assignee] if assignee.present?
      {
        selected: assignee,
        options: users_to_options(attorneys),
        type: AttorneyRewriteTask.name
      }
    end

    def complete_transcription_data(_task, _user)
      {
        modal_body: COPY::COMPLETE_TRANSCRIPTION_BODY,
        modal_hide_instructions: true
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

    def assign_to_pulac_cerullo_data(_task, _user)
      org = PulacCerullo.singleton
      {
        selected: org,
        options: [{ label: org.name, value: org.id }],
        type: PulacCerulloTask.name
      }
    end

    def special_case_movement_data(task, _user = nil)
      {
        selected: task.appeal.assigned_judge,
        options: users_to_options(Judge.list_all),
        type: SpecialCaseMovementTask.name,
        modal_title: COPY::SPECIAL_CASE_MOVEMENT_MODAL_TITLE,
        modal_body: COPY::SPECIAL_CASE_MOVEMENT_MODAL_DETAIL,
        modal_selector_placeholder: COPY::SPECIAL_CASE_MOVEMENT_MODAL_SELECTOR_PLACEHOLDER
      }
    end

    def toggle_timed_hold(task, user)
      action = Constants.TASK_ACTIONS.PLACE_TIMED_HOLD.to_h
      action = Constants.TASK_ACTIONS.END_TIMED_HOLD.to_h if task.on_timed_hold?

      TaskActionHelper.build_hash(action, task, user).merge(returns_complete_hash: true)
    end

    def review_decision_draft(task, user)
      action = Constants.TASK_ACTIONS.REVIEW_LEGACY_DECISION.to_h
      action = Constants.TASK_ACTIONS.REVIEW_AMA_DECISION.to_h if task.ama?
      action = Constants.TASK_ACTIONS.REVIEW_VACATE_DECISION.to_h if task.ama? && task.appeal.vacate?

      TaskActionHelper.build_hash(action, task, user).merge(returns_complete_hash: true)
    end

    private

    def users_to_options(users)
      users.map do |user|
        {
          label: user.full_name,
          value: user.id,
          cssId: user.css_id
        }
      end
    end

    # Exclude users who aren't active or to whom the task is already assigned.
    def potential_task_assignees(task)
      if task.assigned_to.is_a?(Organization)
        task.assigned_to.users.active
      elsif task.parent&.assigned_to.is_a?(Organization)
        task.parent.assigned_to.users.active.reject { |check_user| check_user == task.assigned_to }
      else
        []
      end
    end
  end
end
