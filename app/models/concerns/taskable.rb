# frozen_string_literal: true

module Taskable
  extend ActiveSupport::Concern

  class_methods do
    def has_active_tasks
      belongs_to_appeal_type = "belongs_to_#{name.underscore}".to_sym
      where.not(id: Task.select(:appeal_id).send(belongs_to_appeal_type).inactive).
        where.not(id: Task.select(:appeal_id).send(belongs_to_appeal_type).cancelled_root_task)
    end
  end

  def assigned_attorney
    tasks.includes(:assigned_to).detect { |t| t.is_a?(AttorneyTask) }.try(:assigned_to)
  end

  def assigned_judge
    tasks.includes(:assigned_to).detect { |t| t.is_a?(JudgeTask) }.try(:assigned_to)
  end
end
