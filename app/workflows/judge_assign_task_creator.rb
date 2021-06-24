# frozen_string_literal: true

class JudgeAssignTaskCreator
  def initialize(appeal:, judge:)
    @appeal = appeal
    @judge = judge
  end

  def call
    Rails.logger.info("Assigning judge task for appeal #{appeal.id}")
    task = reassign_or_create
    Rails.logger.info("Assigned judge task with task id #{task.id} to #{task.assigned_to.css_id}")

    Rails.logger.info("Closing distribution task for appeal #{appeal.id}")
    close_distribution_tasks_for_appeal if appeal.is_a?(Appeal)
    Rails.logger.info("Closed distribution task for appeal #{appeal.id}")

    task
  end

  private

  attr_reader :appeal, :judge

  def reassign_or_create
    open_judge_assign_task = @appeal.tasks.open.find_by_type(:JudgeAssignTask)

    return reassign_existing_open_task(open_judge_assign_task) if open_judge_assign_task

    JudgeAssignTask.create!(appeal: appeal, parent: appeal.root_task, assigned_to: judge)
  end

  def reassign_existing_open_task(open_judge_assign_task)
    new_task, _old_task, _new_children = open_judge_assign_task.reassign({
                                                                        assigned_to_type: @judge.class.name,
                                                                        assigned_to_id: @judge.id,
                                                                        appeal: appeal
                                                                      }, current_user)
    new_task
  end

  def close_distribution_tasks_for_appeal
    appeal.tasks.of_type(:DistributionTask).update(status: :completed)
  end
end
