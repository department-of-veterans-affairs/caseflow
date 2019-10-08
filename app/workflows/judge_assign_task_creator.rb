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

  private

  attr_reader :appeal, :judge

  def task
    @task ||= JudgeAssignTask.create!(appeal: appeal, parent: appeal.root_task, assigned_to: judge)
  end

  def close_distribution_tasks_for_appeal
    appeal.tasks.where(type: DistributionTask.name).update(status: :completed)
  end
end
