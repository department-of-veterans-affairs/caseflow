# frozen_string_literal: true

class SameAppealSubstitutionTasksFactory
  def initialize(appeal, selected_task_ids, created_by)
    @appeal = appeal
    @selected_task_ids = selected_task_ids
    @created_by = created_by
  end

  def create_substitute_tasks!
    if @appeal.distributed_to_a_judge?
      create_tasks_for_distributed_appeal
    end
    create_selected_tasks
  end

  def create_tasks_for_distributed_appeal
    if @appeal.docket_type == Constants.AMA_DOCKETS.hearing && selected_tasks_include_hearing_tasks?
      send_hearing_appeal_back_to_distribution
    elsif no_tasks_selected?
      reopen_decision_tasks
    end
  end

  def no_tasks_selected?
    @selected_task_ids.empty?
  end

  def selected_tasks_include_hearing_tasks?
    selected_tasks = Task.where(id: @selected_task_ids).order(:id)
    task_types = [:ScheduleHearingTask, :AssignHearingDispositionTask, :ChangeHearingDispositionTask,
                  :ScheduleHearingColocatedTask, :NoShowHearingTask]
    !selected_tasks.of_type(task_types).empty?
  end

  def send_hearing_appeal_back_to_distribution
    @appeal.root_task.in_progress!
    judge_tasks = [:JudgeAssignTask, :JudgeDecisionReviewTask]
    # TODO: also cancel any open attorney task here
    @appeal.tasks.of_type(judge_tasks).open.each(&:cancelled!)
    params = { assigned_to: Bva.singleton, appeal: @appeal, parent_id: @appeal.root_task.id,
               type: DistributionTask.name }
    DistributionTask.create_child_task(@appeal.root_task, @created_by, params)
  end

  def create_selected_tasks
    return if no_tasks_selected?

    puts("TKTK")
  end

  # TODO: clarify this is correct with product/design or yoom
  # copy existing judge decision review and atty decision tasks and reopen both if they are not already open
  # discussion with JC: only reopen cancelled tasks. do not reopen completed tasks.
  def reopen_decision_tasks
    excluded_attrs = %w[status closed_at placed_on_hold_at]
    # The appeal only has closed attorney tasks and closed judge decision review tasks
    if @appeal.tasks.of_type(:AttorneyTask)&.open&.empty? &&
       @appeal.tasks.of_type(:JudgeDecisionReviewTask)&.open&.empty?
      attorney_task = @appeal.tasks.of_type(:AttorneyTask).closed.order(:id).last
      attorney_task.copy_with_ancestors_to_stream(@appeal, extra_excluded_attributes: excluded_attrs)
    end
  end
end
