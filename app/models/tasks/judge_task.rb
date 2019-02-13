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
  def self.backfill_ramp_appeals_with_tasks(dry_run: true)
    # Find all unassigned tasks and sort them by the NOD date
    tasks = unassigned_ramp_tasks.sort_by { |task| task.appeal.receipt_date }

    if dry_run
      Rails.logger.info("Dry run. Found #{tasks.length} tasks to assign.")
      evidence_count = tasks.select { |task| task.appeal.evidence_submission_docket? }.count
      direct_review_count = tasks.select { |task| task.appeal.direct_review_docket? }.count
      hearing_count = tasks.select { |task| task.appeal.hearing_docket? }.count
      Rails.logger.info("Found #{evidence_count} eligible evidence submission tasks.")
      Rails.logger.info("Found #{direct_review_count} direct review tasks.")
      Rails.logger.info("Found #{hearing_count} hearing tasks.")
      Rails.logger.info("Would assign #{tasks.length}, batch size is #{batch_size}.")
      return
    end

    create_many_from_root_tasks(tasks)
  end

  def self.create_many_from_root_tasks(root_tasks)
    root_tasks.each do |root_task|
      Rails.logger.info("Creating subtasks for appeal #{root_task.appeal.id}")
      RootTask.create_subtasks!(root_task.appeal, root_task)
    end
  end

  def self.unassigned_ramp_tasks
    RootTask.includes(:appeal).all.select { |task| eligible_for_assignment?(task) }
  end

  def self.eligible_for_assignment?(task)
    return false if task.completed?
    return false if task.appeal.nil?
    return false if task.appeal.class == LegacyAppeal
    return false if task.appeal.docket_name.nil?

    task.children.all? { |t| !t.is_a?(JudgeTask) && t.completed? }
  end
  #:nocov:
  # rubocop:enable Metrics/AbcSize
  # rubocop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity
end
