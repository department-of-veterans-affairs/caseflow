# frozen_string_literal: true

class DecisionReviewTasksForInactiveAppealsChecker < DataIntegrityChecker
  def call
    tasks_with_inactive_appeals.each do |task|
      add_to_report "#{task.type} #{task.id} should be cancelled"
      add_to_buffer task.id
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
      suspect_tasks << tasks.select do |task|
        # BoardGrantEffectuationTask only exist for appeals where all the request_issues
        # are decided, so they are not "active". Therefore we want to keep those tasks open.
        next if task.is_a?(BoardGrantEffectuationTask)

        task.appeal.request_issues.active.none?
      end
    end
    suspect_tasks.flatten
  end
end
