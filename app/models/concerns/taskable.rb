# frozen_string_literal: true

module Taskable
  extend ActiveSupport::Concern

  def assigned_attorney
    tasks.where.not(status: "cancelled").order(created_at: :desc).includes(:assigned_to).detect { |t| t.is_a?(AttorneyTask) }.try(:assigned_to)
  end

  def assigned_judge
    tasks.where.not(status: "cancelled").order(created_at: :desc).includes(:assigned_to).detect { |t| t.is_a?(JudgeTask) }.try(:assigned_to)
  end
end
