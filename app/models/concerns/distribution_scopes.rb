# frozen_string_literal: true

module DistributionScopes
  extend ActiveSupport::Concern

  def with_assigned_distribution_task_sql
    # both `appeal_type` and `appeal_id` necessary due to composite index
    <<~SQL
      INNER JOIN tasks AS distribution_task
      ON distribution_task.appeal_type = 'Appeal'
      AND distribution_task.appeal_id = appeals.id
      AND distribution_task.type = 'DistributionTask'
      AND distribution_task.status = 'assigned'
    SQL
  end
end
