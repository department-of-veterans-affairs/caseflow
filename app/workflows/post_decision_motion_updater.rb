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
      disposition: params[:disposition],
      vacate_type: params[:vacate_type]
    )
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

    # We want to create an organization task to serve as parent
    org_task = create_new_task("Organization", abstract_task)
    unless org_task.valid?
      errors.messages.merge!(org_task.errors.messages)
      return
    end

    # Still save org task if assigned user is inactive
    if assigned_to&.inactive?
      org_task.save
    end

    unless assigned_to&.inactive?
      new_task = create_new_task("User", org_task)

      unless new_task.valid?
        errors.messages.merge!(new_task.errors.messages)
        return
      end
      new_task.save
    end

    task.update(status: Constants.TASK_STATUSES.completed)
  end

  def create_abstract_task
    AbstractMotionToVacateTask.new(
      appeal: task.appeal,
      parent: task.parent,
      assigned_to: task.assigned_to
    )
  end

  def create_new_task(assigned_to_type = "User", parent)
    task_class.new(
      appeal: task.appeal,
      parent: parent,
      assigned_by: task.assigned_to,
      assigned_to: ((assigned_to_type == "Organization") ? org : assigned_to),
      assigned_to_type: assigned_to_type,
      instructions: [params[:instructions]]
    )
  end

  def disposition
    params[:disposition]
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

  def org
    denied_or_dismissed? ? LitigationSupport.singleton : judge_team
  end

  def judge
    task.assigned_to
  end

  def judge_team
    JudgeTeam.for_judge(judge)
  end

  def assigned_to
    @assigned_to ||= (denied_or_dismissed? ? prev_motions_attorney : User.find_by(id: params[:assigned_to_id]))
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
