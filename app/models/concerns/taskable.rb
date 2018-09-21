module Taskable
  extend ActiveSupport::Concern

  def assigned_attorney
    tasks.select { |t| t.class == AttorneyTask }.first.try(:assigned_to)
  end

  def assigned_judge
    tasks.select { |t| t.class == JudgeTask }.first.try(:assigned_to)
  end
end
