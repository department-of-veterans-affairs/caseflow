# frozen_string_literal: true

class TaskActionRepository # rubocop:disable Metrics/ClassLength
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

    def mark_task_as_complete_cc(_task, _user = nil)
      {
        modal_body: COPY::MARK_AS_COMPLETE_CONTESTED_CLAIM_DETAIL,
        modal_button_text: COPY::MARK_TASK_COMPLETE_BUTTON_CONTESTED_CLAIM
      }
    end

    def mark_final_notification_letter(_task, _user = nil)
      {
        modal_body: COPY::MARK_AS_COMPLETE_FROM_SEND_FINAL_NOTIFICATION_LETTER_CONTESTED_CLAIM,
        modal_button_text: COPY::MARK_TASK_COMPLETE_BUTTON_CONTESTED_CLAIM
      }
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

    def cancel_initial_letter_task_data(task, _user = nil)
      return_to_name = task.is_a?(AttorneyTask) ? task.parent.assigned_to.full_name : task_assigner_name(task)
      {
        modal_title: COPY::CANCEL_TASK_MODAL_TITLE,
        modal_body: format(COPY::CANCEL_INITIAL_NOTIFICATION_LETTER_TASK_DETAIL, return_to_name),
        message_title: format(COPY::CANCEL_TASK_CONFIRMATION, task.appeal.veteran_full_name),
        message_detail: format(COPY::MARK_TASK_COMPLETE_CONFIRMATION_DETAIL, return_to_name)
      }
    end

    def cancel_post_initial_letter_task_data(task, _user = nil)
      return_to_name = task.is_a?(AttorneyTask) ? task.parent.assigned_to.full_name : task_assigner_name(task)
      {
        modal_title: COPY::CANCEL_TASK_MODAL_TITLE,
        modal_body: format(COPY::CANCEL_POST_INITIAL_NOTIFICATION_LETTER_TASK_DETAIL, return_to_name),
        message_title: format(COPY::CANCEL_TASK_CONFIRMATION, task.appeal.veteran_full_name),
        message_detail: format(COPY::MARK_TASK_COMPLETE_CONFIRMATION_DETAIL, return_to_name)
      }
    end

    def cancel_final_letter_task_data(task, _user = nil)
      return_to_name = task.is_a?(AttorneyTask) ? task.parent.assigned_to.full_name : task_assigner_name(task)
      {
        modal_title: COPY::CANCEL_TASK_MODAL_TITLE,
        modal_body: format(COPY::CANCEL_FINAL_NOTIFICATION_LETTER_TASK_DETAIL, return_to_name),
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
        type: task.appeal_type.eql?(Appeal.name) ? task.type : "JudgeLegacyAssignTask",
        modal_button_text: COPY::MODAL_ASSIGN_BUTTON
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

    def assign_to_attorney_legacy_data(task, user)
      {
        selected: nil,
        options: user.can_act_on_behalf_of_legacy_judges? ? users_to_options(Attorney.list_all) : nil,
        type: task.is_a?(LegacyTask) ? AttorneyLegacyTask.name : AttorneyTask.name,
        message_title: COPY::DISTRIBUTE_TASK_SUCCESS_MESSAGE_NON_BLOCKING
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
      CavcRemandProcessedLetterResponseWindowTask: COPY::CAVC_REMAND_LETTER_RESPONSE_TASK_COMPLETE_MODAL_BODY,
      PostSendInitialNotificationLetterHoldingTask: COPY::PROCEED_FINAL_NOTIFICATION_LETTER_POST_HOLDING_COPY,
      SendInitialNotificationLetterTask: COPY::PROCEED_FINAL_NOTIFICATION_LETTER_INITIAL_COPY
    }.freeze

    def complete_data(task, _user = nil)
      params = {
        modal_body: COMPLETE_TASK_MODAL_BODY_HASH[task.type.to_sym],
        modal_button_text: COPY::MARK_TASK_COMPLETE_BUTTON
      }
      params[:modal_body] = COPY::MARK_TASK_COMPLETE_COPY if params[:modal_body].nil?

      if defined? task.completion_contact
        params[:contact] = task.completion_contact
      end

      params
    end

    def proceed_final_notification_letter_data(task, _user = nil)
      params = {
        modal_body: COMPLETE_TASK_MODAL_BODY_HASH[task.type.to_sym],
        modal_button_text: COPY::PROCEED_FINAL_NOTIFICATION_LETTER_BUTTON
      }

      params[:modal_body] = if task.type == "PostSendInitialNotificationLetterHoldingTask"
                              COPY::PROCEED_FINAL_NOTIFICATION_LETTER_POST_HOLDING_COPY
                            else
                              COPY::PROCEED_FINAL_NOTIFICATION_LETTER_INITIAL_COPY
                            end

      if defined? task.completion_contact
        params[:contact] = task.completion_contact
      end

      params
    end

    def resend_initial_notification_letter_post_holding(_task, _user = nil)
      params = {
        modal_title: COPY::RESEND_INITIAL_NOTIFICATION_LETTER_TITLE,
        modal_body: COPY::RESEND_INITIAL_NOTIFICATION_LETTER_POST_HOLDING_COPY,
        modal_button_text: COPY::RESEND_INITIAL_NOTIFICATION_LETTER_BUTTON
      }

      params
    end

    def resend_initial_notification_letter_final(_task, _user = nil)
      params = {
        modal_title: COPY::RESEND_INITIAL_NOTIFICATION_LETTER_TITLE,
        modal_body: COPY::RESEND_INITIAL_NOTIFICATION_LETTER_FINAL_COPY,
        modal_button_text: COPY::RESEND_INITIAL_NOTIFICATION_LETTER_BUTTON
      }

      params
    end

    def resend_final_notification_letter_task_data(_task, _user = nil)
      params = {
        modal_title: COPY::RESEND_FINAL_NOTIFICATION_LETTER_TITLE,
        modal_body: COPY::RESEND_FINAL_NOTIFICATION_LETTER_COPY,
        modal_button_text: COPY::RESEND_FINAL_NOTIFICATION_LETTER_BUTTON
      }
      params
    end

    def vha_complete_data(task, _user)
      org = Organization.find(task.assigned_to_id)
      org_to_receive = org.is_a?(VhaProgramOffice) ? "VHA CAMO" : "VHA Program Office"
      queue_url = org.url
      {
        modal_title: COPY::DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_MODAL_TITLE,
        modal_button_text: COPY::MODAL_SEND_BUTTON,
        radio_field_label: format(COPY::DOCUMENTS_READY_FOR_ORG_REVIEW_MODAL_BODY, org_to_receive),
        instructions: [],
        type: AssessDocumentationTask.name,
        redirect_after: "/organizations/#{queue_url}?tab=#{completed_tab_url(org)}"
      }
    end

    def schedule_veteran_data(_task, _user = nil)
      {
        selected: nil,
        options: nil,
        type: ScheduleHearingTask.name
      }
    end

    def return_to_attorney_data(task, _user = nil)
      assignee = if task.appeal_type == "LegacyAppeal"
                   task.assigned_to
                 else
                   task.children.select { |child| child.is_a?(AttorneyTask) }.max_by(&:created_at)&.assigned_to
                 end

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
        modal_button_text: COPY::MARK_TASK_COMPLETE_BUTTON,
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
        modal_selector_placeholder: COPY::SPECIAL_CASE_MOVEMENT_MODAL_SELECTOR_PLACEHOLDER,
        modal_button_text: COPY::MODAL_ASSIGN_BUTTON,
        message_title: COPY::DISTRIBUTE_TASK_SUCCESS_MESSAGE_NON_BLOCKING
      }
    end

    def special_case_movement_legacy_data(task, _user = nil)
      {
        selected: task.appeal.assigned_judge,
        options: users_to_options(Judge.list_all),
        type: SpecialCaseMovementTask.name,
        modal_title: COPY::SPECIAL_CASE_MOVEMENT_MODAL_TITLE,
        modal_body: COPY::SPECIAL_CASE_MOVEMENT_MODAL_DETAIL,
        modal_selector_placeholder: COPY::SPECIAL_CASE_MOVEMENT_MODAL_SELECTOR_PLACEHOLDER,
        modal_button_text: COPY::MODAL_ASSIGN_BUTTON,
        message_title: COPY::DISTRIBUTE_TASK_SUCCESS_MESSAGE_NON_BLOCKING
      }
    end

    def blocked_special_case_movement_data(task, _user = nil)
      {
        options: users_to_options(Judge.list_all),
        type: BlockedSpecialCaseMovementTask.name,
        blocking_tasks: task.visible_blocking_tasks.map(&:serialize_for_cancellation)
      }
    end

    def blocked_special_case_movement_data_legacy(task, _user = nil)
      {
        options: users_to_options(Judge.list_all),
        type: BlockedSpecialCaseMovementTask.name
      }
    end

    def toggle_timed_hold(task, user)
      action = Constants.TASK_ACTIONS.PLACE_TIMED_HOLD.to_h
      action = Constants.TASK_ACTIONS.END_TIMED_HOLD.to_h if task.on_timed_hold?

      task_helper = TaskActionHelper.build_hash(action, task, user).merge(
        returns_complete_hash: true
      )

      return task_helper if task.assigned_to.is_a?(User)

      task_helper.merge(
        data: {
          redirect_after:
            "/organizations/#{task.assigned_to.url}?tab=#{po_user(task.assigned_to)}on_hold&page=1"
        }
      )
    end

    def review_decision_draft(task, user)
      action = Constants.TASK_ACTIONS.REVIEW_LEGACY_DECISION.to_h
      action = select_ama_review_decision_action(task) if task.ama?

      TaskActionHelper.build_hash(action, task, user).merge(returns_complete_hash: true)
    end

    def docket_appeal_data(task, _user)
      most_recent_child_task = task.children.first

      # The last organization to work the appeal before sending it to BVA Intake
      # for docketing.
      pre_docket_org = case most_recent_child_task.assigned_to
                       when VhaCamo.singleton then COPY::VHA_CAMO_LABEL
                       when VhaCaregiverSupport.singleton then COPY::VHA_CAREGIVER_LABEL
                       else
                         COPY::EDUCATION_LABEL
                       end

      {
        modal_title: COPY::DOCKET_APPEAL_MODAL_TITLE,
        modal_body: format(COPY::DOCKET_APPEAL_MODAL_BODY, pre_docket_org),
        modal_button_text: COPY::MODAL_CONFIRM_BUTTON,
        modal_alert: COPY::DOCKET_APPEAL_MODAL_NOTICE,
        instructions_label: COPY::PRE_DOCKET_MODAL_BODY,
        redirect_after: "/organizations/#{BvaIntake.singleton.url}"
      }
    end

    def vha_return_to_board_intake(*)
      dropdown_options = downcase_keys(COPY::VHA_RETURN_TO_BOARD_INTAKE_MODAL_DROPDOWN_OPTIONS)
      {
        modal_button_text: COPY::MODAL_RETURN_BUTTON,
        modal_title: COPY::VHA_RETURN_TO_BOARD_INTAKE_MODAL_TITLE,
        type: VhaDocumentSearchTask.name,
        redirect_after: "/organizations/#{VhaCamo.singleton.url}?tab=#{VhaCamoCompletedTasksTab.tab_name}",
        options: dropdown_options
      }
    end

    def vha_documents_ready_for_bva_intake_for_review(*)
      {
        modal_button_text: COPY::MODAL_SEND_BUTTON,
        modal_title: COPY::DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_MODAL_TITLE,
        type: VhaDocumentSearchTask.name,
        body_optional: true,
        redirect_after: "/organizations/#{VhaCamo.singleton.url}?tab=#{VhaCamoCompletedTasksTab.tab_name}"
      }
    end

    def emo_send_to_board_intake_for_review(*)
      {
        modal_title: COPY::DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_MODAL_TITLE,
        modal_button_text: COPY::MODAL_SEND_BUTTON,
        type: EducationDocumentSearchTask.name,
        redirect_after: "/organizations/#{EducationEmo.singleton.url}",
        body_optional: true
      }
    end

    def education_rpo_send_to_board_intake_for_review(task, _user)
      org = Organization.find(task.assigned_to_id)
      queue_url = org.url
      {
        modal_title: COPY::DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_MODAL_TITLE,
        modal_button_text: COPY::MODAL_SEND_BUTTON,
        type: EducationAssessDocumentationTask.name,
        body_optional: true,
        redirect_after: "/organizations/#{queue_url}"
      }
    end

    def vha_assign_to_program_office_data(*)
      {
        options: organizations_to_options(VhaProgramOffice.all),
        modal_title: COPY::VHA_ASSIGN_TO_PROGRAM_OFFICE_MODAL_TITLE,
        modal_button_text: COPY::MODAL_ASSIGN_BUTTON,
        modal_selector_placeholder: COPY::VHA_PROGRAM_OFFICE_SELECTOR_PLACEHOLDER,
        instructions_label: COPY::PRE_DOCKET_MODAL_BODY,
        drop_down_label: COPY::VHA_CAMO_ASSIGN_TO_PROGRAM_OFFICE_DROPDOWN_LABEL,
        type: AssessDocumentationTask.name,
        redirect_after: "/organizations/#{VhaCamo.singleton.url}"
      }
    end

    def vha_assign_to_regional_office_data(task, _user)
      org = Organization.find(task.assigned_to_id)
      queue_url = org.url
      {
        options: {
          vamc: vamcs_to_options,
          visn: visns_to_options
        },
        modal_title: COPY::VHA_ASSIGN_TO_REGIONAL_OFFICE_MODAL_TITLE,
        modal_button_text: COPY::MODAL_ASSIGN_BUTTON,
        modal_selector_placeholder: COPY::VHA_REGIONAL_OFFICE_SELECTOR_PLACEHOLDER,
        body_optional: true,
        instructions: [],
        instructions_label: COPY::VHA_ASSIGN_TO_REGIONAL_OFFICE_INSTRUCTIONS_LABEL,
        drop_down_label: {
          vamc: COPY::VHA_CAMO_ASSIGN_TO_REGIONAL_OFFICE_DROPDOWN_LABEL_VAMC,
          visn: COPY::VHA_CAMO_ASSIGN_TO_REGIONAL_OFFICE_DROPDOWN_LABEL_VISN
        },
        type: AssessDocumentationTask.name,
        redirect_after: "/organizations/#{queue_url}"
      }
    end

    def vha_program_office_return_to_camo(task, _user)
      org = Organization.find(task.assigned_to_id)
      queue_url = org.url
      {
        modal_title: COPY::VHA_PROGRAM_OFFICE_RETURN_TO_CAMO_MODAL_TITLE,
        message_title: COPY::VHA_PROGRAM_OFFICE_RETURN_TO_CAMO_CONFIRMATION_TITLE,
        message_detail: COPY::VHA_PROGRAM_OFFICE_RETURN_TO_CAMO_CONFIRMATION_DETAIL,
        instructions_label: COPY::VHA_CANCEL_TASK_INSTRUCTIONS_LABEL,
        modal_button_text: COPY::MODAL_RETURN_BUTTON,
        type: AssessDocumentationTask.name,
        redirect_after: "/organizations/#{queue_url}?tab=#{po_user(task.assigned_to)}assigned&page=1"
      }
    end

    def vha_regional_office_return_to_program_office(task, _user)
      org = Organization.find(task.assigned_to_id)
      queue_url = org.url
      {
        modal_title: COPY::VHA_REGIONAL_OFFICE_RETURN_TO_PROGRAM_OFFICE_MODAL_TITLE,
        message_title: COPY::VHA_REGIONAL_OFFICE_RETURN_TO_PROGRAM_OFFICE_CONFIRMATION_TITLE,
        message_detail: COPY::VHA_REGIONAL_OFFICE_RETURN_TO_PROGRAM_OFFICE_CONFIRMATION_DETAIL,
        instructions_label: COPY::VHA_CANCEL_TASK_INSTRUCTIONS_LABEL,
        modal_button_text: COPY::MODAL_RETURN_BUTTON,
        type: AssessDocumentationTask.name,
        redirect_after: "/organizations/#{queue_url}?tab=#{po_user(task.assigned_to)}assigned&page=1"
      }
    end

    def bva_intake_return_to_camo(task, _user)
      org = Organization.find(task.assigned_to_id)
      queue_url = org.url
      camo = VhaCamo.singleton
      {
        selected: camo,
        options: [{ label: camo.name, value: camo.id }],
        modal_title: COPY::BVA_INTAKE_RETURN_TO_CAMO_MODAL_TITLE,
        modal_body: COPY::BVA_INTAKE_RETURN_TO_CAMO_MODAL_BODY,
        modal_button_text: COPY::MODAL_RETURN_BUTTON,
        instructions_label: COPY::PRE_DOCKET_MODAL_BODY,
        message_title: format(COPY::BVA_INTAKE_RETURN_TO_CAMO_CONFIRMATION_TITLE, task.appeal.veteran_full_name),
        type: VhaDocumentSearchTask.name,
        redirect_after: "/organizations/#{queue_url}"
      }
    end

    def bva_intake_return_to_caregiver(task, _user)
      org = Organization.find(task.assigned_to_id)
      queue_url = org.url
      caregiver = VhaCaregiverSupport.singleton
      {
        selected: caregiver,
        options: [{ label: caregiver.name, value: caregiver.id }],
        modal_title: COPY::BVA_INTAKE_RETURN_TO_CAREGIVER_MODAL_TITLE,
        modal_body: COPY::BVA_INTAKE_RETURN_TO_CAREGIVER_MODAL_BODY,
        modal_button_text: COPY::MODAL_RETURN_BUTTON,
        instructions_label: COPY::PRE_DOCKET_MODAL_BODY,
        message_title: format(COPY::BVA_INTAKE_RETURN_TO_CAREGIVER_CONFIRMATION_TITLE, task.appeal.veteran_full_name),
        type: VhaDocumentSearchTask.name,
        redirect_after: "/organizations/#{queue_url}"
      }
    end

    def bva_intake_return_to_emo(task, _user)
      org = Organization.find(task.assigned_to_id)
      queue_url = org.url
      emo = EducationEmo.singleton
      {
        selected: emo,
        options: [{ label: emo.name, value: emo.id }],
        modal_title: COPY::BVA_INTAKE_RETURN_TO_EMO_MODAL_TITLE,
        modal_body: COPY::BVA_INTAKE_RETURN_TO_EMO_MODAL_BODY,
        modal_button_text: COPY::MODAL_RETURN_BUTTON,
        instructions_label: COPY::PRE_DOCKET_MODAL_BODY,
        message_title: format(COPY::BVA_INTAKE_RETURN_TO_EMO_CONFIRMATION_TITLE, task.appeal.veteran_full_name),
        type: EducationDocumentSearchTask.name,
        redirect_after: "/organizations/#{queue_url}"
      }
    end

    def vha_mark_task_in_progress(task, _user)
      task_url = task.assigned_to.url
      {
        modal_title: COPY::ORGANIZATION_MARK_TASK_IN_PROGRESS_MODAL_TITLE,
        modal_body: COPY::VHA_CAREGIVER_SUPPORT_MARK_TASK_IN_PROGRESS_MODAL_BODY,
        message_title: COPY::ORGANIZATION_MARK_TASK_IN_PROGRESS_CONFIRMATION_TITLE,
        message_detail: COPY::ORGANIZATION_MARK_TASK_IN_PROGRESS_CONFIRMATION_DETAIL,
        modal_button_text: COPY::MODAL_MARK_TASK_IN_PROGRESS_BUTTON,
        type: AssessDocumentationTask.name,
        redirect_after: "/organizations/#{task_url}?tab=po_inProgressTab&page=1"
      }
    end

    def emo_return_to_board_intake(*)
      {
        modal_title: COPY::EMO_RETURN_TO_BOARD_INTAKE_MODAL_TITLE,
        modal_button_text: COPY::MODAL_RETURN_BUTTON,
        instructions_label: COPY::PRE_DOCKET_MODAL_BODY,
        type: EducationDocumentSearchTask.name,
        redirect_after: "/organizations/#{EducationEmo.singleton.url}"
      }
    end

    def emo_assign_to_education_rpo_data(*)
      {
        options: organizations_to_options(EducationRpo.all),
        modal_title: COPY::EMO_ASSIGN_TO_RPO_MODAL_TITLE,
        modal_button_text: COPY::MODAL_ASSIGN_BUTTON,
        modal_selector_placeholder: COPY::EDUCATION_RPO_SELECTOR_PLACEHOLDER,
        instructions_label: COPY::PRE_DOCKET_MODAL_BODY,
        drop_down_label: COPY::EMO_ASSIGN_TO_RPO_MODAL_BODY,
        type: EducationAssessDocumentationTask.name,
        redirect_after: "/organizations/#{EducationEmo.singleton.url}",
        body_optional: true
      }
    end

    def education_rpo_return_to_emo(task, _user)
      org = Organization.find(task.assigned_to_id)
      queue_url = org.url
      {
        modal_title: COPY::EDUCATION_RPO_RETURN_TO_EMO_MODAL_TITLE,
        message_title: format(
          COPY::EDUCATION_RPO_RETURN_TO_EMO_CONFIRMATION,
          task.appeal.veteran_full_name
        ),
        instructions_label: COPY::PRE_DOCKET_MODAL_BODY,
        type: EducationAssessDocumentationTask.name,
        redirect_after: "/organizations/#{queue_url}",
        modal_button_text: COPY::MODAL_RETURN_BUTTON
      }
    end

    def education_rpo_mark_task_in_progress(task, _user)
      org = Organization.find(task.assigned_to_id)
      queue_url = org.url
      {
        modal_title: COPY::ORGANIZATION_MARK_TASK_IN_PROGRESS_MODAL_TITLE,
        modal_body: COPY::ORGANIZATION_MARK_TASK_IN_PROGRESS_MODAL_BODY,
        message_title: COPY::ORGANIZATION_MARK_TASK_IN_PROGRESS_CONFIRMATION_TITLE,
        message_detail: COPY::ORGANIZATION_MARK_TASK_IN_PROGRESS_CONFIRMATION_DETAIL,
        modal_button_text: COPY::MODAL_MARK_TASK_IN_PROGRESS_BUTTON,
        type: AssessDocumentationTask.name,
        redirect_after: "/organizations/#{queue_url}"
      }
    end

    def vha_caregiver_support_mark_task_in_progress(task, _)
      in_progress_tab_name = VhaCaregiverSupportInProgressTasksTab.tab_name
      {
        modal_title: COPY::VHA_CAREGIVER_SUPPORT_MARK_TASK_IN_PROGRESS_MODAL_TITLE,
        modal_body: COPY::VHA_CAREGIVER_SUPPORT_MARK_TASK_IN_PROGRESS_MODAL_BODY,
        modal_button_text: COPY::MODAL_MARK_TASK_IN_PROGRESS_BUTTON,
        message_title: format(
          COPY::VHA_CAREGIVER_SUPPORT_MARK_TASK_IN_PROGRESS_CONFIRMATION_TITLE,
          task.appeal.veteran_full_name
        ),
        type: VhaDocumentSearchTask.name,
        redirect_after: "/organizations/#{VhaCaregiverSupport.singleton.url}?tab=#{in_progress_tab_name}"
      }
    end

    def vha_caregiver_support_return_to_board_intake(*)
      completed_tab_name = VhaCaregiverSupportCompletedTasksTab.tab_name
      queue_url = "/organizations/#{VhaCaregiverSupport.singleton.url}?tab=#{completed_tab_name}"
      dropdown_options = downcase_keys(COPY::VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE_MODAL_DROPDOWN_OPTIONS)
      {
        modal_title: COPY::VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE_MODAL_TITLE,
        modal_body: COPY::VHA_CAREGIVER_SUPPORT_RETURN_TO_BOARD_INTAKE_MODAL_BODY,
        modal_button_text: COPY::MODAL_RETURN_BUTTON,
        type: VhaDocumentSearchTask.name,
        options: dropdown_options,
        redirect_after: queue_url
      }
    end

    def vha_caregiver_support_send_to_board_intake_for_review(task, _)
      completed_tab_name = VhaCaregiverSupportCompletedTasksTab.tab_name
      {
        modal_title: COPY::DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_MODAL_TITLE,
        modal_button_text: COPY::MODAL_SEND_BUTTON,
        message_title: format(
          COPY::VHA_CAREGIVER_SUPPORT_DOCUMENTS_READY_FOR_BOARD_INTAKE_REVIEW_CONFIRMATION_TITLE,
          task.appeal.veteran_full_name
        ),
        type: VhaDocumentSearchTask.name,
        redirect_after: "/organizations/#{VhaCaregiverSupport.singleton.url}?tab=#{completed_tab_name}",
        body_optional: true
      }
    end

    def send_colocated_task(*)
      {
        modal_button_text: COPY::COLOCATED_ACTION_SEND_TO_ANOTHER_TEAM_BUTTON
      }
    end

    def mark_task_complete_data(*)
      {
        modal_button_text: COPY::MARK_TASK_COMPLETE_BUTTON
      }
    end

    private

    def select_ama_review_decision_action(task)
      return Constants.TASK_ACTIONS.REVIEW_VACATE_DECISION.to_h if task.appeal.vacate?

      Constants.TASK_ACTIONS.REVIEW_AMA_DECISION_SP_ISSUES.to_h
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

    def prepend_visn_id(visn)
      "VISN #{Constants::VISNS_NUMBERED[visn]} - #{visn}"
    end

    def visns_to_options
      VhaRegionalOffice.all.map do |org|
        {
          label: prepend_visn_id(org.name),
          value: org.id
        }
      end
    end

    def vamcs_to_options
      value = -1
      Constants::VHA_VAMCS.map do |office|
        value += 1
        {
          label: office["name"],
          value: value
        }
      end
    end

    def organizations_to_options(organizations)
      organizations&.map do |org|
        {
          label: org.name,
          value: org.id
        }
      end
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

    def downcase_keys(options)
      options.map do |_, value|
        value.transform_keys(&:downcase)
      end
    end

    def completed_tab_url(organization)
      organization.completed_tasks_tab.name
    end

    def po_user(organization)
      return unless organization.is_a?(VhaProgramOffice) || organization.is_a?(VhaRegionalOffice)

      "po_"
    end
  end
end
