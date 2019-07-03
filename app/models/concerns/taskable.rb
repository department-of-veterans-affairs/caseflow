# frozen_string_literal: true

module Taskable
  extend ActiveSupport::Concern

  def assigned_attorney
    tasks.not_cancelled
      .order(created_at: :desc)
      .includes(:assigned_to)
      .detect { |t| t.is_a?(AttorneyTask) }
      .try(:assigned_to)
  end

  def assigned_judge
    tasks.not_cancelled
      .order(created_at: :desc)
      .includes(:assigned_to)
      .detect { |t| t.is_a?(JudgeTask) }
      .try(:assigned_to)
  end
end
