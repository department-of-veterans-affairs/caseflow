# frozen_string_literal: true

class PostDecisionMotionUpdater
  include ActiveModel::Model

  attr_reader :task, :params

  def initialize(task, params)
    @task = task
    @params = params
  end

  def process
    ActiveRecord::Base.transaction do
      motion = create_motion
      return unless motion

      create_new_tasks
    end
  end

  private

  def create_motion
    motion = PostDecisionMotion.new(
      task: task,
      disposition: disposition,
      vacate_type: params[:vacate_type]
    )

    if params.key?(:vacated_decision_issue_ids)
      motion.vacated_decision_issue_ids = params[:vacated_decision_issue_ids]
    end

    unless motion.valid?
      errors.messages.merge!(motion.errors.messages)
      return
    end

    motion.save
  end

  def create_new_tasks
    # We create an AbstractMotionToVacateTask as sibling to the judge task
    # to serve as parent for all successive tasks. It is created when associated with
    # the new task in order to pass responsibility for validation to child task

    abstract_task = create_abstract_task
    unless abstract_task.valid?
      errors.messages.merge!(abstract_task.errors.messages)
      return
    end

    new_task = task_class.new(
      appeal: task.appeal,
      parent: abstract_task,
      assigned_by: task.assigned_to,
      assigned_to: assigned_to,
      instructions: [params[:instructions]]
    )

    unless new_task.valid?
      errors.messages.merge!(new_task.errors.messages)
      return
    end
    new_task.save

    task.update(status: Constants.TASK_STATUSES.completed)
  end

  def create_abstract_task
    AbstractMotionToVacateTask.new(
      appeal: task.appeal,
      parent: task.parent,
      assigned_to: task.assigned_to
    )
  end

  def disposition
    case params[:disposition]
    when "partial"
      "partially_granted"
    else
      params[:disposition]
    end
  end

  def task_class
    @task_class ||= (task_type + "_task").classify.constantize
  end

  def task_type
    grant_type? ? params[:vacate_type] : "#{params[:disposition]}_motion_to_vacate"
  end

  def grant_type?
    %w[granted partial].include? params[:disposition]
  end

  def denied_or_dismissed?
    %w[denied dismissed].include? disposition
  end

  def assigned_to
    @assigned_to ||= (denied_or_dismissed? ? prev_motions_attorney_or_org : User.find_by(id: params[:assigned_to_id]))
  end

  def prev_motions_attorney
    mtv_mail_task.assigned_to
  end

  def prev_motions_attorney_or_org
    prev_motions_attorney.inactive? ? LitigationSupport.singleton : prev_motions_attorney
  end

  def mtv_mail_task
    task.parent
  end
end
