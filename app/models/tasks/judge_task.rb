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


  # This function to be run in production when we need to ass
  def self.assign_judge_tasks_for_unassigned_ramp_appeals(dry_run: false)


    # Find all root tasks with no children, that means they are not assigned.
    root_tasks_needing_assignment = RootTask.left_outer_joins(:children).all.select { |t| t.children.empty? }
    root_tasks_needing_assignment.each do |root_task|

    if (dry_run)
      puts "Dry run. Would assign judge task for #{root_task.appeal.id} to #{next_assignee.css_id}"
    else
      task = create!(appeal: root_task.appeal, 
        parent: root_task, 
        action: "assign", 
        appeal_type: "Appeal", 
        assigned_at: DateTime.now,
        assigned_to: next_assignee)

      puts "Assigned judge task with id: #{task.id} to #{task.assigned_to}"
    end
  end

  # 2 judges for now just to test
  def self.list_of_assignees
    %w[BVAAABSHIRE BVAOFRANECKI]
  end
end
