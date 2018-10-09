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
    fail Caseflow::Error::TooManyChildTasks, task_id: id if children_attorney_tasks.length > 1
    children_attorney_tasks[0]
  end

  #:nocov:
  # rubocop:disable Metrics/AbcSize
  # This function to be manually run in production when we need to fetch all RAMP
  # appeals that are eligible for assignment to judges, and assign them.
  def self.assign_ramp_judge_tasks(dry_run: false, batch_size: 10)
    # Find all unassigned tasks, sort them by the NOD date, and take the first N.
    tasks = unassigned_ramp_tasks.sort_by { |task| task.appeal.receipt_date }[0..batch_size - 1]

    if dry_run
      Rails.logger.info("Dry run. Found #{unassigned_ramp_tasks.length} tasks to assign.")
      evidence_count = unassigned_ramp_tasks.select { |task| task.appeal.evidence_submission_docket? }.count
      direct_review_count = unassigned_ramp_tasks.select { |task| task.appeal.direct_review_docket? }.count
      Rails.logger.info("Found #{evidence_count} eligible evidence submission tasks.")
      Rails.logger.info("Found #{direct_review_count} direct review tasks.")
      Rails.logger.info("Would assign #{tasks.length}, batch size is #{batch_size}.")
      Rails.logger.info("First assignee would be #{next_assignee.css_id}")
      return
    end

    assign_judge_tasks_for_root_tasks(tasks)
  end

  def self.assign_judge_tasks_for_root_tasks(root_tasks)
    root_tasks.each do |root_task|
      Rails.logger.info("Assigning judge task for appeal #{root_task.appeal.id}")
      task = create(appeal: root_task.appeal,
                    parent: root_task,
                    appeal_type: Appeal.name,
                    assigned_at: Time.zone.now,
                    assigned_to: next_assignee)
      Rails.logger.info("Assigned judge task with task id #{task.id} to #{task.assigned_to.css_id}")
    end
  end

  def self.unassigned_ramp_tasks
    RootTask.includes(:appeal).all.select { |task| eligible_for_assigment?(task) }
  end

  def self.eligible_for_assigment?(task)
    # Hearing cases will not be processed until February 2019
    return false if task.appeal.hearing_docket?

    # If it's an evidence submission case, we need to wait until the
    # evidence submission window is over
    if task.appeal.evidence_submission_docket?
      return false if task.appeal.receipt_date > 90.days.ago
    end

    # If the task already has been assigned to a judge, or if it
    # is a VSO task, it will have children tasks. We only want to
    # assign tasks that have not been assigned yet.
    task.children.empty?
  end

  def self.list_of_assignees
    Constants::RampJudges::USERS[Rails.current_env]
  end
  #:nocov:
  # rubocop:enable Metrics/AbcSize
end
