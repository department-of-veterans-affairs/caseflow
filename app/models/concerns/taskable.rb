# frozen_string_literal: true

module Taskable
  extend ActiveSupport::Concern

  def assigned_attorney
    tasks.not_cancelled
      .order(created_at: :desc)
      .includes(:assigned_to)
      .detect { |t| t.is_a?(AttorneyTask) && !t.is_a?(DocketSwitchAbstractAttorneyTask) }
      .try(:assigned_to)
  end

  def assigned_judge
    tasks.not_cancelled
      .order(created_at: :desc)
      .includes(:assigned_to)
      .detect { |t| t.is_a?(JudgeTask) }
      .try(:assigned_to)
  end

  def overtime?
    return !!work_mode&.overtime if FeatureToggle.enabled?(:overtime_revamp, user: RequestStore.store[:current_user])

    false
  end

  def overtime=(overtime)
    WorkMode.create_or_update_by_appeal(self, overtime: overtime)
  end
end
