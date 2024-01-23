# frozen_string_literal: true

# A same appeal substitution is a pending appeal substitution.
# It means that after the appellant substitution occurs, a separate appeal is not created,
# i.e., the appellant substitution occurs on the same appeal.
class SameAppealSubstitutionTasksFactory
  include TasksFactoryConcern

  def initialize(appeal, task_ids, created_by, task_params, skip_cancel_tasks = false)
    @appeal = appeal
    @task_ids = task_ids
    @created_by = created_by
    @task_params = task_params
    @skip_cancel_tasks = skip_cancel_tasks
  end

  def create_substitute_tasks!
    if @appeal.distributed_to_a_judge?
      create_tasks_for_distributed_appeal
    else
      create_selected_tasks
    end
    cancel_unselected_tasks unless @skip_cancel_tasks
  end

  def cancel_unselected_tasks
    cancel_tasks = Task.where(id: @task_ids[:cancelled])
    cancel_tasks.each do |task|
      task.update!(
        status: Constants.TASK_STATUSES.cancelled,
        cancellation_reason: Constants.TASK_CANCELLATION_REASONS.substitution,
        cancelled_by_id: RequestStore[:current_user]&.id,
        closed_at: Time.zone.now
      )
    end
  end

  def create_tasks_for_distributed_appeal
    if @appeal.hearing_docket? && hearing_task_selected?
      send_hearing_appeal_back_to_distribution
    elsif evidence_submission_task_selected?
      resume_evidence_submission
    elsif no_tasks_selected?
      reopen_decision_tasks
    end
  end

  def hearing_task_selected?
    selected_tasks.of_type(Constants.TASKS_FOR_APPELLANT_SUBSTITUTION.hearing).any?
  end

  def evidence_submission_task_selected?
    selected_tasks.of_type(:EvidenceSubmissionWindowTask).any?
  end

  def no_tasks_selected?
    @task_ids[:selected].empty?
  end

  def send_hearing_appeal_back_to_distribution
    @appeal.root_task.in_progress!
    @appeal.tasks.of_type(Constants.TASKS_FOR_APPELLANT_SUBSTITUTION.decision).open.each(&:cancelled!)

    params = { assigned_to: Bva.singleton, appeal: @appeal, parent_id: @appeal.root_task.id,
               type: DistributionTask.name }
    DistributionTask.create_child_task(@appeal.root_task, @created_by, params)
  end

  def resume_evidence_submission
    esw_task = @appeal.tasks.of_type(:EvidenceSubmissionWindowTask).closed.order(:id).last
    esw_task_params = @task_params[esw_task.id.to_s]

    create_evidence_submission_window_task(@appeal, esw_task, esw_task_params)

    @appeal.tasks.of_type(Constants.TASKS_FOR_APPELLANT_SUBSTITUTION.decision).each do |task|
      task.update!(cancellation_reason: Constants.TASK_CANCELLATION_REASONS.substitution)
    end
    @appeal.tasks.of_type(Constants.TASKS_FOR_APPELLANT_SUBSTITUTION.decision).open.each(&:cancelled!)
  end

  private

  def selected_tasks
    Task.where(id: @task_ids[:selected]).order(:id)
  end

  def create_selected_tasks
    return if no_tasks_selected?

    source_tasks = selected_tasks
    fail "Expecting only tasks assigned to organizations" if source_tasks.map(&:assigned_to_type).include?("User")

    # We need to clean up existing tree if starting fresh for hearings
    cancel_defunct_hearing_tasks if source_tasks.any? { |task| task.is_a?(ScheduleHearingTask) }

    source_tasks.each do |source_task|
      creation_params = @task_params[source_task.id.to_s]
      create_task_from(source_task, creation_params)
    end.flatten
  end

  ATTRIBUTES_EXCLUDED_FROM_TASK_COPY = %w[id created_at updated_at
                                          status closed_at placed_on_hold_at
                                          cancelled_by_id cancellation_reason].freeze

  def copy_task(task)
    new_task_attributes = task.attributes
      .except(*ATTRIBUTES_EXCLUDED_FROM_TASK_COPY)
    Task.create!(new_task_attributes)
  end

  def create_task_from(source_task, creation_params)
    case source_task.type
    when "EvidenceSubmissionWindowTask"
      create_evidence_submission_window_task(@appeal, source_task, creation_params)
    when "ScheduleHearingTask"
      distribution_task = @appeal.tasks.open.find_by(type: :DistributionTask)
      ScheduleHearingTask.create!(appeal: @appeal, parent: distribution_task)
    else
      copy_task(source_task)
    end
  end

  def last_cancelled_attorney_task
    @appeal.tasks.of_type(:AttorneyTask).cancelled.order(:id).last
  end

  def reopen_decision_tasks
    if @appeal.tasks.of_type(:AttorneyTask).open.empty? &&
       @appeal.tasks.of_type(:JudgeDecisionReviewTask).open.empty?
      copy_task(last_cancelled_attorney_task) if last_cancelled_attorney_task
    end
  end

  def distribution_task
    @distribution_task ||= @appeal.tasks.open.find_by(type: :DistributionTask) ||
                           DistributionTask.create!(appeal: @appeal, parent: @root_task)
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
        cancellation_reason: Constants.TASK_CANCELLATION_REASONS.substitution,
        cancelled_by_id: RequestStore[:current_user]&.id,
        closed_at: Time.zone.now
      )
    end
  end
end
