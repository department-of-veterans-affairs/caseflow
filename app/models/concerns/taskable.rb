# frozen_string_literal: true

module Taskable
  extend ActiveSupport::Concern

  def assigned_attorney
    tasks.includes(:assigned_to).detect { |t| t.is_a?(AttorneyTask) }.try(:assigned_to)
  end

  def assigned_judge
    tasks.includes(:assigned_to).detect { |t| t.is_a?(JudgeTask) }.try(:assigned_to)
  end
end
