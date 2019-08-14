# frozen_string_literal: true

class VacateMotionMailTask < MailTask

  VACATE_MOTION_AVAILABLE_ACTIONS = [
    Constants.TASK_ACTIONS.LIT_SUPPORT_PULAC_CERULLO.to_h
  ].freeze

  def available_actions(user)
    if LitigationSupport.singleton.user_has_access?(user)
      return super + VACATE_MOTION_AVAILABLE_ACTIONS
    end

    super
  end

  def self.create_child_task(parent, current_user, params)
    Task.create!(
      type: ReviewMotionToVacateTask.name,
      appeal: parent.appeal,
      assigned_by_id: child_assigned_by_id(parent, current_user),
      parent_id: parent.id,
      assigned_to: child_task_assignee(parent, params),
      instructions: params[:instructions]
    )
  end

  def self.label
    COPY::VACATE_MOTION_MAIL_TASK_LABEL
  end

  def self.default_assignee(_parent)
    LitigationSupport.singleton
  end
end
