# frozen_string_literal: true

class BulkTaskReassignment
  class NoTasksToReassign < StandardError; end
  class MoreTasksToReassign < StandardError; end
  class InvalidTaskParent < StandardError; end
  class InvalidTaskAssignee < StandardError; end

  def initialize(user)
    if user.nil?
      fail ArgumentError, "expected valid user"
    end

    @user = user
  end

  def perform_dry_run
    @dry_run = true

    process
  end

  def process
    check_error_states_of_tasks

    ActiveRecord::Base.multi_transaction do
      # Handles tasks of a specific type, must be called first
      reassign_judge_assign_tasks
      reassign_judge_review_tasks
      reassign_attorney_tasks

      # Handles all other open tasks
      all_other_tasks = open_tasks.where.not(type: [JudgeAssignTask, JudgeDecisionReviewTask, AttorneyTask].map(&:name))
      reassign_tasks_with_parent_org_tasks(all_other_tasks)
      reassign_tasks_with_parent_user_tasks(all_other_tasks)
    end

    ensure_user_has_no_open_tasks
  end

  private

  attr_reader :user, :dry_run

  def cancel
    dry_run ? "Would cancel" : "Cancelling"
  end

  def reassign
    dry_run ? "Would reassign" : "Reassigning"
  end

  def create
    dry_run ? "create" : "creating"
  end

  def move
    dry_run ? "move" : "moving"
  end

  def open_tasks
    @open_tasks ||= fetch_open_tasks_for_user
  end

  def fetch_open_tasks_for_user
    Task.open.includes(:parent).where(assigned_to: user)
  end

  def new_supervising_judge_from_task(task)
    assignee_judge_teams = task.assigned_to.organizations.where(type: JudgeTeam.name)
    assignee_judge_teams.where.not(name: user.css_id).first&.judge
  end

  def reassignment_instructions(status_change_verb = "reassigned")
    format(COPY::BULK_REASSIGN_INSTRUCTIONS, status_change_verb, user.css_id)
  end

  def update_task_status_with_instructions(task, status)
    task.update_with_instructions(status: status, instructions: reassignment_instructions(status))
  end

  def check_error_states_of_tasks
    # Check for tasks in a bad state as outlined in
    # department-of-veterans-affairs/caseflow/blob/4fd949f3fb77c0aa0ec2854a3e5310a320aecd03/docs/11811_tech_spec.md
    ensure_user_has_tasks
    ensure_all_tasks_have_parents
    ensure_all_org_parent_tasks_have_same_type
    ensure_all_user_parent_tasks_have_different_type
    ensure_all_judge_assign_tasks_are_child_free
    ensure_all_judge_review_tasks_have_child_attorney_tasks
    ensure_all_judge_review_tasks_have_new_judge
  end

  def ensure_user_has_tasks
    fail NoTasksToReassign, "There aren't any open tasks assigned to this user." if open_tasks.empty?
  end

  def ensure_all_tasks_have_parents
    tasks_with_no_parent = open_tasks.where(parent_id: nil).pluck(:id)

    if tasks_with_no_parent.any?
      fail InvalidTaskParent, "Open tasks (#{tasks_with_no_parent.sort.join(', ')}) " \
                              "assigned to the user have no parent task"
    end
  end

  def ensure_all_org_parent_tasks_have_same_type
    tasks_with_org_parents_of_mismatched_type = open_tasks
      .where.not(type: [JudgeAssignTask.name, JudgeDecisionReviewTask.name])
      .where("parents_tasks.assigned_to_type = ? AND parents_tasks.type != tasks.type", Organization.name)
      .pluck(:id)

    if tasks_with_org_parents_of_mismatched_type.any?
      fail InvalidTaskParent, "Open tasks (#{tasks_with_org_parents_of_mismatched_type.sort.join(', ')})" \
                              " assigned to the user have parent task assigned to an organization but has a " \
                              "different task type"
    end
  end

  def ensure_all_user_parent_tasks_have_different_type
    tasks_with_user_parents_of_same_type = open_tasks
      .where("parents_tasks.assigned_to_type = ? AND parents_tasks.type = tasks.type", User.name)
      .pluck(:id)

    if tasks_with_user_parents_of_same_type.any?
      fail InvalidTaskParent, "Open tasks (#{tasks_with_user_parents_of_same_type.sort.join(', ')}) " \
                              "assigned to the user have parent task assigned to a user but has the same type"
    end
  end

  def ensure_all_judge_assign_tasks_are_child_free
    open_children_of_judge_assign_tasks = Task.open
      .where(parent: open_tasks.of_type(:JudgeAssignTask))
      .pluck(:id)

    if open_children_of_judge_assign_tasks.any?
      fail InvalidTaskParent, "JudgeAssignTasks have open children " \
                              "(#{open_children_of_judge_assign_tasks.sort.join(', ')})"
    end
  end

  # We rely on the child attorney task's assigned attorney to determine what judge to reassign the decision review to
  def ensure_all_judge_review_tasks_have_child_attorney_tasks
    judge_review_task_ids = open_tasks.of_type(:JudgeDecisionReviewTask).pluck(:id)
    child_attorney_tasks = AttorneyTask.not_cancelled.where(parent_id: judge_review_task_ids)
    judge_review_tasks_without_children = (judge_review_task_ids - child_attorney_tasks.pluck(:parent_id))

    if judge_review_tasks_without_children.any?
      fail InvalidTaskParent, "JudgeDecisionReviewTasks " \
                              "(#{judge_review_tasks_without_children.sort.join(', ')}) " \
                              "have no valid child attorney tasks"
    end
  end

  def ensure_all_judge_review_tasks_have_new_judge
    judge_review_tasks = open_tasks.of_type(:JudgeDecisionReviewTask)
    child_attorney_tasks = AttorneyTask.not_cancelled.where(parent: judge_review_tasks)
    tasks_without_judges = child_attorney_tasks.select { |task| new_supervising_judge_from_task(task).nil? }

    if tasks_without_judges.any?
      fail InvalidTaskAssignee, "AttorneyTasks (#{tasks_without_judges.map(&:id).sort.join(', ')}) assignee does " \
                                "not belong to a judge team with an active judge"
    end
  end

  def ensure_user_has_no_open_tasks
    if !dry_run
      tasks = fetch_open_tasks_for_user.pluck(:id)
      if tasks.any?
        fail MoreTasksToReassign, "Open tasks (#{tasks.sort.join(', ')}) still open after reassign"
      end
    end
  end

  # Cancels any JudgeAssignTasks and puts the cases back to "ready for distribution"
  def reassign_judge_assign_tasks
    judge_assign_tasks = open_tasks.of_type(:JudgeAssignTask)

    if judge_assign_tasks.any?
      task_ids = judge_assign_tasks.pluck(:id).sort
      message = "#{cancel} #{task_ids.count} JudgeAssignTasks with ids #{task_ids.join(', ')} and #{create} " \
                "#{task_ids.count} DistributionTasks"
      Rails.logger.info(message)

      if !dry_run
        judge_assign_tasks.each do |task|
          DistributionTask.create!(appeal: task.appeal, parent: task.appeal.root_task)
          update_task_status_with_instructions(task, Constants.TASK_STATUSES.cancelled)
        end
      end
    end
  end

  # Reassigns any JudgeDecisionReviewTasks to the child AttorneyTask's assigned attorney's judge based on their
  # JudgeTeam membership.
  # Assumes the attorney has been placed on a new JudgeTeam
  def reassign_judge_review_tasks
    judge_review_tasks = open_tasks.of_type(:JudgeDecisionReviewTask)

    if judge_review_tasks.any?
      task_ids = judge_review_tasks.pluck(:id).sort
      message = "#{cancel} #{task_ids.count} JudgeDecisionReviewTasks with ids #{task_ids.join(', ')} and #{move} " \
                "#{task_ids.count} AttorneyTasks to new JudgeDecisionReviewTasks assigned to the attorney's new judge"
      Rails.logger.info(message)

      if !dry_run
        judge_review_tasks.each do |task|
          attorney_task = task.children_attorney_tasks.not_cancelled.order(:assigned_at).last
          reassign_judge_review_task(task, attorney_task)
        end
      end
    end
  end

  def reassign_judge_review_task(task, attorney_task)
    reassigned_tasks = task.reassign(
      {
        assigned_to_type: User.name,
        assigned_to_id: new_supervising_judge_from_task(attorney_task).id,
        instructions: reassignment_instructions
      },
      task.assigned_by
    )

    # Move the attorney task under the new JudgeDecisionReviewTask assigned to the new judge
    attorney_task.update!(parent: reassigned_tasks.first)
  end

  # Cancels all AttorneyTasks and their parent JudgeDecisionReviewTask and opens a new JudgeAssignTask for each
  def reassign_attorney_tasks
    attorney_tasks = open_tasks.of_type(:AttorneyTask)

    if attorney_tasks.any?
      task_ids = attorney_tasks.pluck(:id).sort
      parent_task_ids = attorney_tasks.pluck(:parent_id).sort
      message = "#{cancel} #{task_ids.count} AttorneyTasks with ids #{task_ids.join(', ')}, JudgeDecisionReviewTasks " \
                "with ids #{parent_task_ids.join(', ')}, and #{create} #{task_ids.count} JudgeAssignTasks"
      Rails.logger.info(message)

      if !dry_run
        attorney_tasks.each do |task|
          reassign_attorney_task(task)
        end
      end
    end
  end

  def reassign_attorney_task(task)
    _attorney_task, _judge_decision_task, judge_assign_task = task.send_back_to_judge_assign!(
      status: Constants.TASK_STATUSES.cancelled,
      instructions: reassignment_instructions(Constants.TASK_STATUSES.cancelled)
    )
    judge_assign_task.update_with_instructions(
      instructions: reassignment_instructions(Constants.TASK_STATUSES.assigned)
    )
  end

  def reassign_tasks_with_parent_org_tasks(tasks)
    parents_assigned_to_orgs = Task.where(id: tasks.pluck(:parent_id), assigned_to_type: Organization.name)
    tasks_with_parent_org_tasks = tasks.where(parent: parents_assigned_to_orgs)

    parents_assigned_to_orgs.distinct.pluck(:assigned_to_id).each do |org_id|
      organization = Organization.find(org_id)
      parents_assigned_to_org = parents_assigned_to_orgs.where(assigned_to: organization)
      child_tasks_of_org = tasks_with_parent_org_tasks.where(parent: parents_assigned_to_org)
      if organization.automatically_assign_to_member?
        reassign_automatically_assigned_org_tasks(child_tasks_of_org, organization)
      else
        reassign_manually_assigned_org_tasks(parents_assigned_to_org, child_tasks_of_org)
      end
    end
  end

  # Reassigns all tasks under organizations that use a RoundRobinTaskDistributor to other members of that organization
  # Assumes the user has been removed from this organization, which will automatically happen if they are made inactive
  def reassign_automatically_assigned_org_tasks(tasks, organization)
    active_org_user_count = organization.users.active.count

    task_ids = tasks.pluck(:id).sort
    message = "#{reassign} #{task_ids.count} tasks with ids #{task_ids.join(', ')} to #{active_org_user_count} " \
              "members of the parent tasks' organization"
    Rails.logger.info(message)

    if !dry_run
      tasks.in_groups(active_org_user_count, false).each do |task_group|
        next_assignee_id = organization.next_assignee.id
        task_group.each do |task|
          task.reassign(
            {
              assigned_to_type: User.name,
              assigned_to_id: next_assignee_id,
              instructions: reassignment_instructions
            }, task.assigned_by
          )
        end
      end
    end
  end

  # Cancels all user tasks and makes thie parent tasks available for manual reassignment
  def reassign_manually_assigned_org_tasks(parent_tasks, tasks)
    task_ids = tasks.pluck(:id).sort
    message = "#{cancel} #{task_ids.count} tasks with ids #{task_ids.join(', ')} and #{move} #{task_ids.count} parent" \
              " tasks back to the organization's unassigned queue tab"
    Rails.logger.info(message)

    if !dry_run
      parent_tasks.update_all(status: Constants.TASK_STATUSES.assigned)
      tasks.each { |task| update_task_status_with_instructions(task, Constants.TASK_STATUSES.cancelled) }
    end
  end

  # Cancels all user tasks and makes the parent tasks available for manual reassignment
  def reassign_tasks_with_parent_user_tasks(tasks)
    parents_assigned_to_users = Task.where(id: tasks.pluck(:parent_id), assigned_to_type: User.name)
    tasks_with_parent_user_tasks = tasks.where(parent: parents_assigned_to_users)

    if tasks_with_parent_user_tasks.any?
      task_ids = tasks_with_parent_user_tasks.pluck(:id).sort
      message = "#{cancel} #{task_ids.count} tasks with ids #{task_ids.join(', ')} and #{move} #{task_ids.count} "\
                "parent tasks back to the parent's assigned user's assigned tab"
      Rails.logger.info(message)

      if !dry_run
        parents_assigned_to_users.update_all(status: Constants.TASK_STATUSES.assigned)
        tasks_with_parent_user_tasks.each do |task|
          update_task_status_with_instructions(task, Constants.TASK_STATUSES.cancelled)
        end
      end
    end
  end
end
