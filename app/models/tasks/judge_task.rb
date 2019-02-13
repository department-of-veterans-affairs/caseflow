class JudgeTask < Task
  def available_actions(user)
    additional_available_actions(user).unshift(Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h)
  end

  def actions_available?(user)
    assigned_to == user
  end

  def additional_available_actions(_user)
    fail Caseflow::Error::MustImplementInSubclass
  end

  def timeline_title
    COPY::CASE_TIMELINE_JUDGE_TASK
  end

  def previous_task
    fail Caseflow::Error::TooManyChildTasks, task_id: id if children_attorney_tasks.length > 1

    children_attorney_tasks[0]
  end

  #:nocov:
  # rubocop:disable Metrics/AbcSize
  # rubocop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  # This function to be manually run in production when we need to fetch all RAMP
  # appeals that are eligible for assignment to judges, and assign them. This and related methods
  # can be removed after AMA day.
  def self.assign_ramp_judge_tasks(dry_run: true, batch_size: 10)
    # Find all unassigned tasks, sort them by the NOD date, and take the first N.
    tasks = unassigned_ramp_tasks.sort_by { |task| task.appeal.receipt_date }[0..batch_size - 1]

    if dry_run
      Rails.logger.info("Dry run. Found #{unassigned_ramp_tasks.length} tasks to assign.")
      evidence_count = unassigned_ramp_tasks.select { |task| task.appeal.evidence_submission_docket? }.count
      direct_review_count = unassigned_ramp_tasks.select { |task| task.appeal.direct_review_docket? }.count
      Rails.logger.info("Found #{evidence_count} eligible evidence submission tasks.")
      Rails.logger.info("Found #{direct_review_count} direct review tasks.")
      Rails.logger.info("Would assign #{tasks.length}, batch size is #{batch_size}.")
      Rails.logger.info("First assignee would be #{JudgeAssignTaskDistributor.new.next_assignee.css_id}")
      return
    end

    create_many_from_root_tasks(tasks)
  end

  def self.create_many_from_root_tasks(root_tasks)
    root_tasks.each do |root_task|
      Rails.logger.info("Assigning judge task for appeal #{root_task.appeal.id}")

      task = JudgeAssignTask.create!(
        appeal: root_task.appeal,
        parent: root_task,
        appeal_type: Appeal.name,
        assigned_at: Time.zone.now,
        assigned_to: JudgeAssignTaskDistributor.new.next_assignee
      )
      Rails.logger.info("Assigned judge task with task id #{task.id} to #{task.assigned_to.css_id}")
    end
  end

  def self.unassigned_ramp_tasks
    RootTask.includes(:appeal).all.select { |task| eligible_for_assignment?(task) }
  end

  def self.eligible_for_assignment?(task)
    return false if !task.active?
    return false if task.appeal.nil?
    return false if task.appeal.class == LegacyAppeal
    return false if task.appeal.docket_name.nil?
    # Hearing cases will not be processed until February 2019
    return false if task.appeal.hearing_docket?

    # If it's an evidence submission case, we need to wait until the
    # evidence submission window is over
    if task.appeal.evidence_submission_docket?
      return false if task.appeal.receipt_date > 90.days.ago
    end

    task.children.all? { |t| !t.is_a?(JudgeTask) && !t.active? }
  end
  #:nocov:
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity
end
