module Taskable
  extend ActiveSupport::Concern

  def assigned_attorney
    tasks.detect { |t| t.is_a?(AttorneyTask) }.try(:assigned_to)
  end

  def assigned_judge
    tasks.detect { |t| t.is_a?(JudgeTask) }.try(:assigned_to)
  end
end
