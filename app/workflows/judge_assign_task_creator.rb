# frozen_string_literal: true

class JudgeAssignTaskCreator
  def initialize(appeal:, judge:, genpop:)
    @appeal = appeal
    @judge = judge
    @genpop = genpop
  end

  def call
    Rails.logger.info("Assigning judge task for appeal #{appeal.id}")
    Rails.logger.info("Assigned judge task with task id #{task.id} to #{task.assigned_to.css_id}")
    Rails.logger.info("Closing distribution task for appeal #{appeal.id}")

    close_distribution_tasks_for_appeal

    Rails.logger.info("Closed distribution task for appeal #{appeal.id}")

    [task, genpop]
  end

  private

  attr_reader :appeal, :judge, :genpop

  def task
    @task ||= JudgeAssignTask.create!(appeal: appeal, parent: appeal.root_task, assigned_to: judge)
  end

  def close_distribution_tasks_for_appeal
    appeal.tasks.where(type: DistributionTask.name).update(status: :completed)
  end
end
