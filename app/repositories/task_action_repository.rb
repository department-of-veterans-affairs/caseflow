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

    def mail_assign_to_organization_data(task, user = nil)
      options = MailTask.subclass_routing_options(user: user, appeal: task.appeal)
      valid_options = task.appeal.outcoded? ? options : options.reject { |opt| opt[:value] == "VacateMotionMailTask" }
      { options: valid_options }
    end

    def cancel_task_data(task, _user = nil)
      return_to_name = task.is_a?(AttorneyTask) ? task.parent.assigned_to.full_name : task_assigner_name(task)
      {
        modal_title: COPY::CANCEL_TASK_MODAL_TITLE,
        modal_body: format(COPY::CANCEL_TASK_MODAL_DETAIL, return_to_name),
        message_title: format(COPY::CANCEL_TASK_CONFIRMATION, task.appeal.veteran_full_name),
        message_detail: format(COPY::MARK_TASK_COMPLETE_CONFIRMATION_DETAIL, return_to_name)
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
        message_detail: format(COPY::MARK_TASK_COMPLETE_CONFIRMATION_DETAIL, task_assigner_name(task))
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

    def assign_to_hearings_user_data(task, user = nil)
      users = [HearingsManagement, HearingAdmin, TranscriptionTeam].map { |team| team.singleton.users }.flatten.uniq

      {
        selected: user,
        options: users_to_options(users),
        type: task.type
      }
    end

    def assign_to_user_data(task, user = nil)
      users = potential_task_assignees(task)
      extras = if task.is_a?(HearingAdminActionTask)
                 {
                   redirect_after: "/organizations/#{HearingsManagement.singleton.url}",
                   message_detail: COPY::HEARING_ASSIGN_TASK_SUCCESS_MESSAGE_DETAIL
                 }
               elsif task.is_a?(SendCavcRemandProcessedLetterTask) && task.assigned_to_type == "Organization"
                 { redirect_after: "/organizations/#{CavcLitigationSupport.singleton.url}" }
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

    def assign_to_attorney_data(task, user)
      {
        selected: nil,
        options: user.can_act_on_behalf_of_judges? ? users_to_options(Attorney.list_all) : nil,
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
      judge_attorneys = JudgeTeam.for_judge(task.assigned_to)&.attorneys
      {
        selected: attorney,
        options: users_to_options([judge_attorneys.presence || Attorney.list_all, attorney].flatten.compact.uniq),
        type: PostDecisionMotion.name
      }
    end

    def sign_motion_to_vacate_data(_task, _user = nil)
      {}
    end

    def docket_switch_send_to_judge_data(_task, _user = nil)
      {
        type: DocketSwitchRulingTask.name
      }
    end

    def docket_switch_ruling_data(task, _user = nil)
      {
        selected: task.assigned_by&.id,
        options: ClerkOfTheBoard.singleton.users.select(&:attorney?).map do |user|
          { value: user.id, label: user.full_name }
        end
      }
    end

    def docket_switch_denied_data(_task, _user = nil)
      {
        type: DocketSwitchDeniedTask.name
      }
    end

    def docket_switch_granted_data(_task, _user = nil)
      {
        type: DocketSwitchGrantedTask.name
      }
    end

    def cavc_add_blocking_distrbution_admin_action_data(task, org, task_type)
      {
        selected: org,
        options: [{ label: org.name, value: org.id }],
        type: task_type.name,
        parent_id: DistributionTask.open.find_by(appeal: task.appeal)&.id,
        modal_body: format(COPY::CAVC_SEND_TO_TEAM_BLOCKING_DISTRIBUTION_DETAIL, task_type.label, org.name),
        redirect_after: "/queue/appeals/#{task.appeal.external_id}"
      }
    end

    def assign_to_translation_team_blocking_distribution_data(task, _user = nil)
      cavc_add_blocking_distrbution_admin_action_data(task, Translation.singleton, TranslationTask)
    end

    def assign_to_transciption_team_blocking_distribution_data(task, _user = nil)
      cavc_add_blocking_distrbution_admin_action_data(task, TranscriptionTeam.singleton, TranscriptionTask)
    end

    def assign_to_privacy_team_blocking_distribution_data(task, _user = nil)
      cavc_add_blocking_distrbution_admin_action_data(task, PrivacyTeam.singleton, PrivacyActTask)
    end

    def assign_ihp_to_colocated_blocking_distribution_data(task, _user = nil)
      cavc_add_blocking_distrbution_admin_action_data(task, Colocated.singleton, IhpColocatedTask)
    end

    def assign_schedule_hearing_to_hearings_blocking_distribution_data(task, _user = nil)
      cavc_add_blocking_distrbution_admin_action_data(task, Bva.singleton, ScheduleHearingTask)
    end

    def assign_poa_to_cavc_blocking_cavc_data(task, _user = nil)
      org = CavcLitigationSupport.singleton
      task_type = CavcPoaClarificationTask
      cavc_add_blocking_distrbution_admin_action_data(task, org, task_type).merge(
        modal_body: format(COPY::CAVC_SEND_TO_TEAM_BLOCKING_CAVC_DETAIL, task_type.label, org.name),
        parent_id: task.id
      )
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

    def cancel_convert_hearing_request_type_data(task, _user = nil)
      {
        redirect_after: "/queue/appeals/#{task.appeal.external_id}",
        modal_title: COPY::CANCEL_CONVERT_HEARING_TYPE_TO_VIRTUAL_MODAL_TITLE,
        message_title: format(COPY::CANCEL_TASK_CONFIRMATION, task.appeal.veteran_full_name),
        message_detail: COPY::CANCEL_CONVERT_HEARING_TYPE_TO_VIRTUAL_SUCCESS_DETAIL,
        show_instructions: false
      }
    end

    def change_hearing_request_type_data(_task, _user = nil)
      {}
    end

    def change_task_type_data(task, user = nil)
      if task.is_a? MailTask
        mail_assign_to_organization_data(task, user)
      else
        legacy_and_colocated_task_add_admin_action_data(task, user)
      end
    end

    COMPLETE_TASK_MODAL_BODY_HASH = {
      NoShowHearingTask: COPY::NO_SHOW_HEARING_TASK_COMPLETE_MODAL_BODY,
      HearingAdminActionTask: COPY::HEARING_SCHEDULE_COMPLETE_ADMIN_MODAL,
      SendCavcRemandProcessedLetterTask: COPY::SEND_CAVC_REMAND_PROCESSED_LETTER_TASK_COMPLETE_MODAL_BODY,
      CavcRemandProcessedLetterResponseWindowTask: COPY::CAVC_REMAND_LETTER_RESPONSE_TASK_COMPLETE_MODAL_BODY
    }.freeze

    def complete_data(task, _user = nil)
      params = { modal_body: COMPLETE_TASK_MODAL_BODY_HASH[task.type.to_sym] }
      params[:modal_body] = COPY::MARK_TASK_COMPLETE_COPY if params[:modal_body].nil?

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

    # Cancel the underlying task, and cancels the hearing or hearing request.
    #
    # @note This task action can be called for either the AssignHearingDispositionTask or the ScheduleHearingTask.
    #   The main difference between those contexts is that a hearing will exist for an AssignHearingDispositionTask,
    #   but not for a ScheduleHearingTask.
    def withdraw_hearing_data(task, _user)
      copy = select_withdraw_hearing_copy(task.appeal)
      is_an_assign_hearing_disposition_task = task.is_a?(AssignHearingDispositionTask)

      {
        redirect_after: "/queue/appeals/#{task.appeal.external_id}",
        modal_title: COPY::WITHDRAW_HEARING_MODAL_TITLE,
        modal_body: copy["MODAL_BODY"],
        message_title: format(COPY::WITHDRAW_HEARING_SUCCESS_MESSAGE_TITLE, task.appeal.veteran_full_name),
        message_detail: format(copy["SUCCESS_MESSAGE"], task.appeal.veteran_full_name),
        # If a hearing has already been scheduled, the cancel task should also cancel the hearing. To do that
        # it will need to provide the cancelled disposition and action to the API.
        business_payloads: if is_an_assign_hearing_disposition_task
                             {
                               values: {
                                 disposition: Constants.HEARING_DISPOSITION_TYPES.cancelled
                               }
                             }
                           end,
        # If a hearing was already scheduled and is being withdrawn, it doesn't make sense to
        # return back to the hearing schedule, so don't show the link in that case.
        back_to_hearing_schedule: is_an_assign_hearing_disposition_task ? false : true
      }
    end

    def add_schedule_hearing_task_admin_actions_data(task, user)
      schedule_hearing_action_path = if FeatureToggle.enabled?(:schedule_veteran_virtual_hearing, user: user)
                                       Constants.TASK_ACTIONS.SCHEDULE_VETERAN_V2_PAGE.value
                                     else
                                       Constants.TASK_ACTIONS.SCHEDULE_VETERAN.value
                                     end

      {
        redirect_after: "/queue/appeals/#{task.appeal.external_id}",
        schedule_hearing_action_path: schedule_hearing_action_path,
        message_detail: COPY::ADD_HEARING_ADMIN_TASK_CONFIRMATION_DETAIL,
        selected: nil,
        options: HearingAdminActionTask.subclasses.sort_by(&:label).map do |subclass|
          { value: subclass.name, label: subclass.label }
        end
      }
    end

    def flag_conflict_of_jurisdiction_data(_task, _user)
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

    def blocked_special_case_movement_data(task, _user = nil)
      {
        options: users_to_options(Judge.list_all),
        type: BlockedSpecialCaseMovementTask.name,
        blocking_tasks: task.visible_blocking_tasks.map(&:serialize_for_cancellation)
      }
    end

    def toggle_timed_hold(task, user)
      action = Constants.TASK_ACTIONS.PLACE_TIMED_HOLD.to_h
      action = Constants.TASK_ACTIONS.END_TIMED_HOLD.to_h if task.on_timed_hold?

      TaskActionHelper.build_hash(action, task, user).merge(returns_complete_hash: true)
    end

    def review_decision_draft(task, user)
      action = Constants.TASK_ACTIONS.REVIEW_LEGACY_DECISION.to_h
      action = select_ama_review_decision_action(task, user) if task.ama?

      TaskActionHelper.build_hash(action, task, user).merge(returns_complete_hash: true)
    end

    private

    def select_ama_review_decision_action(task, user)
      return Constants.TASK_ACTIONS.REVIEW_VACATE_DECISION.to_h if task.appeal.vacate?

      if FeatureToggle.enabled?(:special_issues_revamp, user: user)
        return Constants.TASK_ACTIONS.REVIEW_AMA_DECISION_SP_ISSUES.to_h
      end

      Constants.TASK_ACTIONS.REVIEW_AMA_DECISION.to_h
    end

    def select_withdraw_hearing_copy(appeal)
      if appeal.is_a?(Appeal)
        COPY::WITHDRAW_HEARING["AMA"]
      elsif appeal.representative_is_colocated_vso? # a colocated vso is also part of `Service Organization`
        COPY::WITHDRAW_HEARING["LEGACY_COLOCATED_POA"]
      elsif appeal.representative_is_organization?
        COPY::WITHDRAW_HEARING["LEGACY_NON_COLOCATED_ORGANIZATION"]
      elsif appeal.representative_is_agent?
        COPY::WITHDRAW_HEARING["LEGACY_NON_COLOCATED_PRIVATE_ATTORNEY"]
      else
        # Assumption: the above Legacy POA cases are comprehensive meaning the catch-all
        #             case will only happen if there is no POA.
        COPY::WITHDRAW_HEARING["LEGACY_NO_POA"]
      end
    end

    def task_assigner_name(task)
      task.assigned_by&.full_name || "the assigner"
    end

    def users_to_options(users)
      users.map do |user|
        {
          label: user.full_name,
          value: user.id
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
