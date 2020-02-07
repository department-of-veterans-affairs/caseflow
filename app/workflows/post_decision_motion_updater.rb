# frozen_string_literal: true

##
# The PostDecisionMotionUpdater validates and creates a PostDecisionMotion from the JudgeAddressMotionToVacateTask,
# and creates the subsequent tasks or appeal streams.

class PostDecisionMotionUpdater
  include ActiveModel::Model

  attr_reader :task, :params, :disposition, :instructions

  def initialize(task, params)
    @task = task
    @params = params
    @disposition = @params[:disposition]
    @instructions = @params[:instructions]
  end

  delegate :appeal, to: :task

  def process
    ActiveRecord::Base.transaction do
      return unless post_decision_motion

      handle_denial_or_dismissal
      handle_grant

      return if errors.messages.any?

      task.update(status: Constants.TASK_STATUSES.completed)
    end
  end

  private

  def post_decision_motion
    @post_decision_motion ||= create_motion
  end

  def create_motion
    motion = PostDecisionMotion.new(
      task: task,
      disposition: disposition,
      vacate_type: params[:vacate_type]
    )

    if disposition == "partially_granted"
      motion.vacated_decision_issue_ids = params[:vacated_decision_issue_ids]
    elsif disposition == "granted"
      # For full grant, auto populate all decision issue IDs
      motion.vacated_decision_issue_ids = appeal.decision_issues.map(&:id)
    end

    unless motion.valid?
      errors.messages.merge!(motion.errors.messages)
      return
    end

    motion.save
  end

  # We create an AbstractMotionToVacateTask as sibling to the JudgeAddressMotionToVacateTask
  # to serve as parent for successive Denied or Dismissed tasks. It is created when associated with
  # the new task in order to pass responsibility for validation to child task
  def handle_denial_or_dismissal
    return unless denied_or_dismissed?

    abstract_task = create_abstract_task
    unless abstract_task.valid?
      errors.messages.merge!(abstract_task.errors.messages)
      return
    end

    new_task = create_new_task(abstract_task)

    unless new_task.valid?
      errors.messages.merge!(new_task.errors.messages)
      return
    end
    new_task.save
  end

  def handle_grant
    return unless grant_type?

    vacate_stream = appeal.create_stream("Vacate")
    create_new_stream_tasks(vacate_stream)
  end

  def create_abstract_task
    AbstractMotionToVacateTask.new(
      appeal: appeal,
      parent: task.parent,
      assigned_to: judge_user
    )
  end

  def create_new_task(parent)
    task_class.new(
      appeal: appeal,
      parent: parent,
      assigned_by: judge_user,
      assigned_to: attorney_user,
      instructions: [instructions]
    )
  end

  def create_new_stream_tasks(stream)
    InitialTasksFactory.new(stream).create_root_and_sub_tasks!

    jdrt = JudgeDecisionReviewTask.create!(appeal: stream, parent: stream.root_task, assigned_to: judge_user)
    attorney_task = AttorneyTask.new(
      appeal: stream, parent: jdrt, assigned_by: judge_user, assigned_to: attorney_user, instructions: [instructions]
    )

    unless attorney_task.valid?
      errors.messages.merge!(attorney_task.errors.messages)
      return
    end

    attorney_task.save
  end

  def task_class
    @task_class ||= (task_type + "_task").classify.constantize
  end

  def task_type
    "#{disposition}_motion_to_vacate"
  end

  def grant_type?
    %w[granted partially_granted].include? disposition
  end

  def denied_or_dismissed?
    %w[denied dismissed].include? disposition
  end

  def judge_user
    task.assigned_to
  end

  def attorney_user
    @attorney_user ||= denied_or_dismissed? ? prev_motions_attorney : User.find_by(id: params[:assigned_to_id])
  end

  def prev_motions_attorney
    task.parent.assigned_to
  end

  def prev_motions_attorney_or_org
    prev_motions_attorney.inactive? ? LitigationSupport.singleton : prev_motions_attorney
  end
end
