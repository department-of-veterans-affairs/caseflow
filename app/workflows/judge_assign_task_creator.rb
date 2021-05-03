# frozen_string_literal: true

class JudgeAssignTaskCreator
  def initialize(appeal:, judge:)
    @appeal = appeal
    @judge = judge
  end

  def call
    Rails.logger.info("Assigning judge task for appeal #{appeal.id}")
    Rails.logger.info("Assigned judge task with task id #{task.id} to #{task.assigned_to.css_id}")
    Rails.logger.info("Closing distribution task for appeal #{appeal.id}")

    close_distribution_tasks_for_appeal if appeal.is_a?(Appeal)

    Rails.logger.info("Closed distribution task for appeal #{appeal.id}")

    task
  end

  def manage_judge_assign_tasks_for_appeal
    current_judge_assign_tasks = @appeal.tasks.open.of_type(:JudgeAssignTask)
    if current_judge_assign_tasks.blank?
      call
    else
      judge_task = current_judge_assign_tasks.first
      updated_judge_tasks = judge_task.reassign({
                                                  assigned_to_type: @judge.class.name,
                                                  assigned_to_id: @judge.id,
                                                  appeal: appeal
                                                }, current_user)
      close_distribution_tasks_for_appeal
      updated_judge_tasks.find { |task| task.type == JudgeAssignTask.name && task.open? }
    end
  end

  private

  attr_reader :appeal, :judge

  def task
    @task ||= JudgeAssignTask.create!(appeal: appeal, parent: appeal.root_task, assigned_to: judge)
  end

  def close_distribution_tasks_for_appeal
    appeal.tasks.of_type(:DistributionTask).update(status: :completed)
  end
end
