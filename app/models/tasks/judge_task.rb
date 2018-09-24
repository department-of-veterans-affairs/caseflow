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
  def self.assign_ramp_judge_tasks(dry_run: false)
    # Find all root tasks with no children, that means they are not assigned.
    root_tasks_needing_assignment = RootTask.left_outer_joins(:children).all.select { |t| t.children.empty? }
    root_tasks_needing_assignment.each do |root_task|
      if dry_run
        Rails.logger.info("Dry run. Would assign judge task for #{root_task.appeal.id} to #{next_assignee.css_id}")
      else
        task = create!(appeal: root_task.appeal,
                       parent: root_task,
                       action: "assign",
                       appeal_type: "Appeal",
                       assigned_at: Time.zone.now,
                       assigned_to: next_assignee)

        Rails.logger.info("Assigned judge task with id: #{task.id} to #{task.assigned_to}")
      end
    end
  end

  def self.assign_ramp_judge_tasks_for_vso_appeals(dry_run: false)
    # Find all root tasks with no children, that means they are not assigned.

    tasks = GenericTask.
      .where(assigned_to_type: "Vso")
      .where("completed_at IS NULL")
      .where("parent_id IS NOT NULL")
      .where("assigned at < ?", 30.days.ago)

    root_tasks_needing_assignment = RootTask.left_outer_joins(:children).all.select { |t| t.children.empty? }
    root_tasks_needing_assignment.each do |root_task|
      if dry_run
        Rails.logger.info("Dry run. Would assign judge task for #{root_task.appeal.id} to #{next_assignee.css_id}")
      else
        task = create!(appeal: root_task.appeal,
                       parent: root_task,
                       action: "assign",
                       appeal_type: "Appeal",
                       assigned_at: Time.now,
                       assigned_to: next_assignee)

        Rails.logger.info("Assigned judge task with id: #{task.id} to #{task.assigned_to}")
      end
    end
  end

  # 2 judges for now just to test
  # TODO: add production list.
  def self.list_of_assignees
    %w[BVAAABSHIRE BVAOFRANECKI]
  end
  #:nocov:
end
