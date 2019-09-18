# frozen_string_literal: true

class DecisionReviewTasksForInactiveAppealsChecker < DataIntegrityChecker
  def call
    tasks_with_inactive_appeals.each do |task|
      add_to_report "#{task.type} #{task.id} should be cancelled"
    end
  end

  private

  def tasks_with_inactive_appeals
    @tasks_with_inactive_appeals ||= build_task_list
  end

  def build_task_list
    suspect_tasks = []
    BusinessLine.all.each do |business|
      tasks = business.tasks.open.includes([:assigned_to, :appeal])
      suspect_tasks << tasks.select { |task| task.appeal.request_issues.active.none? }
    end
    suspect_tasks.flatten
  end
end
