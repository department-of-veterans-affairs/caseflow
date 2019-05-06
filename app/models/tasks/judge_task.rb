# frozen_string_literal: true

##
# Parent class for all tasks to be completed by judges, including
# JudgeQualityReviewTasks, JudgeDecisionReviewTasks,
# JudgeDispatchReturnTasks, and JudgeAssignTasks.

class JudgeTask < Task
  def available_actions(user)
    [
      Constants.TASK_ACTIONS.ADD_ADMIN_ACTION.to_h,
      additional_available_actions(user)
    ].flatten
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
    children_attorney_tasks.order(:assigned_at).last
  end

  #:nocov:
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
      Rails.logger.info("Would assign #{tasks.length}.")
      return
    end

    backfill_tasks(tasks)
  end

  def self.backfill_tasks(root_tasks)
    transaction do
      root_tasks.each do |root_task|
        Rails.logger.info("Creating subtasks for appeal #{root_task.appeal.id}")
        RootTask.create_subtasks!(root_task.appeal, root_task)
        distribution_task = DistributionTask.find_by(parent: root_task)
        # Update any open IHP tasks if they exist so that they block distribution.
        ihp_task = InformalHearingPresentationTask.active.find_by(appeal: root_task.appeal)
        ihp_task&.update!(parent: distribution_task)
        # Ensure direct review appeals have their decision date set.
        root_task.appeal.set_target_decision_date!
      end
    end
  end

  def self.unassigned_ramp_tasks
    RootTask.includes(:appeal).all.select { |task| eligible_for_backfill?(task) }
  end

  def self.eligible_for_backfill?(task)
    # All RAMP appeals have completed RootTasks.
    return false if !task.active?
    return false if task.appeal.nil?
    return false if task.appeal.class != Appeal
    return false if task.appeal.docket_name.nil?

    task.children.all? { |t| !t.is_a?(JudgeTask) }
  end
  #:nocov:
end
