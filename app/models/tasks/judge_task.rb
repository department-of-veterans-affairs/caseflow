class JudgeTask < Task
  include Timer

  def when_expired; end

  def actions_available?(user)
    assigned_to == user
  end

  def timeline_title
    COPY::CASE_TIMELINE_JUDGE_TASK
  end

  def self.create_from_params(params, user)
    new_task = super(params, user)

    parent = Task.find(params[:parent_id]) if params[:parent_id]
    if parent && parent.is_a?(QualityReviewTask)
      parent.update!(status: :on_hold)
    end

    new_task
  end

  def self.modify_params(params)
    super(params.merge(type: JudgeAssignTask.name))
  end

  def self.verify_user_can_create!(user)
    QualityReview.singleton.user_has_access?(user) || super(user)
  end

  def update_from_params(params, _current_user)
    return super unless parent && parent.is_a?(QualityReviewTask)

    params["instructions"] = [instructions, params["instructions"]].flatten if params.key?("instructions")

    update_status(params.delete("status")) if params.key?("status")
    update(params)

    [self]
  end

  def when_child_task_completed
    update!(type: JudgeReviewTask.name)
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

      task = JudgeAssignTask.create!(
        appeal: root_task.appeal,
        parent: root_task,
        appeal_type: Appeal.name,
        assigned_at: Time.zone.now,
        assigned_to: next_assignee
      )
      Rails.logger.info("Assigned judge task with task id #{task.id} to #{task.assigned_to.css_id}")
    end
  end

  def self.unassigned_ramp_tasks
    RootTask.includes(:appeal).all.select { |task| eligible_for_assigment?(task) }
  end

  def self.eligible_for_assigment?(task)
    return false if task.appeal.class == LegacyAppeal
    return false if task.appeal.docket_name.nil?
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
