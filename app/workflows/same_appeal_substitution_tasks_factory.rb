# frozen_string_literal: true

class SameAppealSubstitutionTasksFactory
  def initialize(appeal, selected_task_ids)
    @appeal = appeal
    @selected_task_ids = selected_task_ids
  end

  def create_substitute_tasks!
    @appeal.distributed_to_a_judge? ? create_tasks_for_distributed_appeal : create_tasks_for_undistributed_appeal
  end

  def create_tasks_for_distributed_appeal
    if @appeal.docket_type == Constants.AMA_DOCKETS.hearing && selected_tasks_include_hearing_tasks?
      send_hearing_appeal_back_to_distribution
    elsif no_tasks_selected?
      reopen_decision_tasks
    end
    create_selected_tasks
  end

  def no_tasks_selected?
    @selected_task_ids.empty?
  end

  def selected_tasks_include_hearing_tasks?
    puts("TKTK")
  end

  def send_hearing_appeal_back_to_distribution
    puts("TKTK")
  end

  def create_selected_tasks
    return if no_tasks_selected?

    puts("TKTK")
  end
  # TODO: clarify this is correct with product/design
  # copy existing judge decision review and atty decision tasks and reopen both if they are not already open
  def reopen_decision_tasks
    # TODO: attorney decision tasks copy_with_ancestors_to stream (reopen it, exclude the status and closed_at on_hold_at)
    puts("TKTK")
  end


  def create_tasks_for_undistributed_appeal
    create_selected_tasks
  end
end
