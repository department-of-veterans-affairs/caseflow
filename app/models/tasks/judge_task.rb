class JudgeTask < Task
  validates :action, inclusion: { in: %w[assign review] }

  include RoundRobinAssigner

  def self.create(params)
    super(params.merge(action: "assign"))
  end

  def when_child_task_completed
    update!(action: :review)
    super
  end

  def previous_task
    children_attorney_tasks = children.where(type: "AttorneyTask")
    fail Caseflow::Error::TooManyChildTasks, task_id: id if children_attorney_tasks.length > 1
    children_attorney_tasks[0]
  end

  #:nocov:
  # This function to be manually run in production when we need to assign judge tasks.
  def self.assign_ramp_judge_tasks(dry_run: false, batch_size: 10)
    # Find all root tasks with no children, that means they are not assigned.
    tasks = unassigned_ramp_tasks.sort_by(&:created_at)[0..batch_size - 1]

    if dry_run
      Rails.logger.info("Dry run. Found #{unassigned_ramp_tasks.length} tasks to assign.")
      Rails.logger.info("Would assign #{tasks.length} tasks.")
      Rails.logger.info("First assignee would be #{next_assignee.css_id}")
      return
    end

    assign_judge_tasks(tasks)
  end

  def self.assign_judge_tasks_for_root_tasks(root_tasks)
    root_tasks.each do |root_task|
      Rails.logger.info("Assigning judge task for appeal #{root_task.appeal.id}")
      task = create(appeal: root_task.appeal,
                    parent: root_task,
                    appeal_type: "Appeal",
                    assigned_at: Time.zone.now,
                    assigned_to: next_assignee)
      Rails.logger.info("Assigned judge task with task id #{task.id} to #{task.assigned_to.css_id}")
    end
  end

  def self.unassigned_ramp_tasks
    RootTask.left_outer_joins(:children).all.select { |t| t.children.empty? }
  end

  def self.list_of_assignees
    Constants::RampJudges::USERS[Rails.current_env]
  end
  #:nocov:
end
