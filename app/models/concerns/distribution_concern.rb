# frozen_string_literal: true

module DistributionConcern
  extend ActiveSupport::Concern

  private

  def assign_judge_tasks_for_appeals(appeals, judge)
    appeals.map do |appeal|
      next nil unless appeal.tasks.open.of_type(:JudgeAssignTask).count == 0

      distribution_task_assignee_id = appeal.tasks.of_type(:DistributionTask).first.assigned_to_id
      Rails.logger.info("Calling JudgeAssignTaskCreator for appeal #{appeal.id} with judge #{judge.css_id}")
      JudgeAssignTaskCreator.new(appeal: appeal,
                                 judge: judge,
                                 assigned_by_id: distribution_task_assignee_id).call
    end
  end

  def cancel_previous_judge_assign_task(appeal, judge_id)
    appeal.tasks.of_type(:JudgeAssignTask).where.not(assigned_to_id: judge_id).update(status: :cancelled)
  end
end
