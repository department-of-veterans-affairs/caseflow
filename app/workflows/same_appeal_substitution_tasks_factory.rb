# frozen_string_literal: true

class SameAppealSubstitutionTasksFactory
  def initialize(appeal, selected_task_ids, created_by, task_params)
    @appeal = appeal
    @selected_task_ids = selected_task_ids
    @created_by = created_by
    @task_params = task_params
  end

  def create_substitute_tasks!
    if @appeal.distributed_to_a_judge?
      create_tasks_for_distributed_appeal
    else
      create_selected_tasks
    end
  end

  def create_tasks_for_distributed_appeal
    if @appeal.docket_type == Constants.AMA_DOCKETS.hearing && selected_tasks_include_hearing_tasks?
      send_hearing_appeal_back_to_distribution
    elsif evidence_submission_task_selected?
      resume_evidence_submission
    elsif no_tasks_selected?
      reopen_decision_tasks
    end
  end

  def evidence_submission_task_selected?
    selected_tasks = Task.where(id: @selected_task_ids).order(:id)
    !selected_tasks.of_type(:EvidenceSubmissionWindowTask).empty?
  end

  ATTRIBUTES_EXCLUDED_FROM_TASK_COPY = %w[id created_at updated_at
                                          status closed_at placed_on_hold_at].freeze

  def copy_task_with_ancestors(task)
    return unless task.parent

    new_task_attributes = task
      .attributes
      .except(*ATTRIBUTES_EXCLUDED_FROM_TASK_COPY, ["parent_id"])

    existing_new_parent = @appeal.reload.tasks.open.find { |t| t.type == task.parent.type }
    new_parent = existing_new_parent || copy_task_with_ancestors(task.parent)

    return unless new_parent

    new_task_attributes["parent_id"] = new_parent.id
    Task.create!(new_task_attributes)
  end

  def resume_evidence_submission
    # TODO: figure out if i need to consider cases where there are multiple cancelled esw tasks. do i need a test for this?
    esw_task = @appeal.tasks.of_type(:EvidenceSubmissionWindowTask).cancelled.order(:id).last
    copy_task_with_ancestors(esw_task)
    decision_tasks = [:JudgeAssignTask, :AttorneyTask, :JudgeDecisionReviewTask]
    @appeal.tasks.of_type(decision_tasks).each { |task| task.update!(cancellation_reason: "substitution") }
    @appeal.tasks.of_type(decision_tasks).open.each(&:cancelled!)
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
    decision_tasks = [:JudgeAssignTask, :JudgeDecisionReviewTask, :AttorneyTask]
    @appeal.tasks.of_type(decision_tasks).open.each(&:cancelled!)

    params = { assigned_to: Bva.singleton, appeal: @appeal, parent_id: @appeal.root_task.id,
               type: DistributionTask.name }
    DistributionTask.create_child_task(@appeal.root_task, @created_by, params)
  end

  private

  def create_selected_tasks
    return if no_tasks_selected?

    source_tasks = Task.where(id: @selected_task_ids).order(:id)

    fail "Expecting only tasks assigned to organizations" if source_tasks.map(&:assigned_to_type).include?("User")

    # We need to clean up existing tree if starting fresh for hearings
    cancel_defunct_hearing_tasks if source_tasks.any? { |task| task.is_a?(ScheduleHearingTask) }

    source_tasks.each do |source_task|
      creation_params = @task_params[source_task.id.to_s]
      create_task_from(source_task, creation_params)
    end.flatten
  end

  def copy_task(task)
    new_task_attributes = task.attributes
      .except(*ATTRIBUTES_EXCLUDED_FROM_TASK_COPY)
    Task.create!(new_task_attributes)
  end

  def create_task_from(source_task, creation_params)
    case source_task.type
    when "EvidenceSubmissionWindowTask"
      InitialTasksFactory.new(@appeal).evidence_submission_window_task(source_task, creation_params)
    when "ScheduleHearingTask"
      distribution_task = @appeal.tasks.open.find_by(type: :DistributionTask)
      ScheduleHearingTask.create!(appeal: @appeal, parent: distribution_task)
    else
      copy_task(source_task)
    end
  end

  def reopen_decision_tasks
    if @appeal.tasks.of_type(:AttorneyTask)&.open&.empty? &&
       @appeal.tasks.of_type(:JudgeDecisionReviewTask)&.open&.empty?
      attorney_task = @appeal.tasks.of_type(:AttorneyTask).cancelled.order(:id).last
      if attorney_task
        copy_task(attorney_task)
      end
    end
  end

  # Called if a `ScheduleHearingTask` is selected to be reopened
  # :reek:FeatureEnvy
  def cancel_defunct_hearing_tasks
    types_to_cancel = [
      AssignHearingDispositionTask.name,
      ChangeHearingDispositionTask.name,
      EvidenceSubmissionWindowTask.name,
      TranscriptionTask.name
    ]
    tasks_to_cancel = @appeal.tasks.select { |task| types_to_cancel.include?(task.type) && task.open? }
    tasks_to_cancel.each do |task|
      task.update!(
        status: Constants.TASK_STATUSES.cancelled,
        cancellation_reason: Constants.TASK_CANCELLATION_REASONS.substitution
      )
    end
  end
end
