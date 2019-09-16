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
    # If it is a grant, judge assigns it to the drafting attorney,
    # otherwise, it goes back to the motions attorney

    new_task = task_class.new(
      appeal: task.appeal,
      parent: task.root_task,
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

  def task_class
    @task_class ||= (task_type + "_task").classify.constantize
  end

  def task_type
    (params[:disposition] == "granted") ? params[:vacate_type] : "#{params[:disposition]}_motion_to_vacate"
  end

  def assigned_to
    @assigned_to ||= User.find_by(id: params[:assigned_to_id])
  end
end
