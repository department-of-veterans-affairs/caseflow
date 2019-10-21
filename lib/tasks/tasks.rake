# frozen_string_literal: true

namespace :tasks do
  class InvalidTaskType < StandardError; end
  class InvalidOrganization < StandardError; end
  class NoTasksToChange < StandardError; end
  class NoTasksToReassign < StandardError; end
  class InvalidTaskParent < StandardError; end
  class InvalidTaskAssignee < StandardError; end

  # usage:
  # Change all HoldHearingTasks to AssignHearingDispositionTask (dry run)
  #   $ bundle exec rake tasks:change_type[HoldHearingTask,AssignHearingDispositionTask]"
  # Change all HoldHearingTasks to DispositionTasks (execute)
  #   $ bundle exec rake tasks:change_type[HoldHearingTask,DispositionTask,false]"
  # Change HoldHearingTasks matching passed ids to DispositionTasks (dry run)
  #   $ bundle exec rake tasks:change_type[HoldHearingTask,DispositionTask,12,13,14,15,16]"
  # Change HoldHearingTasks matching passed ids to DispositionTasks (execute)
  #   $ bundle exec rake tasks:change_type[HoldHearingTask,DispositionTask,false,12,13,14,15,16]"
  desc "change tasks from one type to another"
  task :change_type, [:from_type, :to_type, :dry_run] => :environment do |_, args|
    Rails.logger.tagged("rake tasks:change_type") { Rails.logger.info("Invoked with: #{args.to_a.join(', ')}") }
    extras = args.extras
    dry_run = args.dry_run&.to_s&.strip&.upcase != "FALSE"
    if dry_run && args.dry_run.to_i > 0
      extras.unshift(args.dry_run)
    end

    if dry_run
      puts "*** DRY RUN"
      puts "*** pass 'false' as the third argument to execute"
    end

    from_class = Object.const_get(args.from_type)
    to_class = Object.const_get(args.to_type)
    [from_class, to_class].each do |check_class|
      unless Task.descendants.include?(check_class)
        fail InvalidTaskType, "#{check_class.name} is not a valid Task type!"
      end
    end

    target_tasks = if extras.any?
                     from_class.find(extras)
                   else
                     from_class.all
                   end

    if target_tasks.count == 0
      fail NoTasksToChange, "There aren't any #{from_class.name}s available to change."
    end

    ids = target_tasks.map(&:id)
    change = dry_run ? "Would change" : "Changing"
    revert = dry_run ? "Would revert" : "Revert"
    message = "#{change} #{target_tasks.count} #{from_class.name}s with ids #{ids.join(', ')} into #{to_class.name}s"
    puts message
    puts "#{revert} with: bundle exec rake tasks:change_type[#{to_class.name},#{from_class.name},#{ids.join(',')}]"

    if !dry_run
      Rails.logger.tagged("rake tasks:change_type") { Rails.logger.info(message) }
      target_tasks.each do |task|
        task.update!(type: to_class.name)
      end
    end
  end

  # usage:
  # Assign all HearingTasks assigned to org with id 1 to org with id 2 (dry run)
  #   $ bundle exec rake tasks:change_organization_assigned_to[HearingTasks,1,2]"
  # Assign all HearingTasks assigned to org with id 1 to org with id 2 (execute)
  #   $ bundle exec rake tasks:change_organization_assigned_to[HearingTask,1,2,false]"
  # Assign all HearingTasks matching passed ids and assigned to org with id 1 to org with id 2 (dry run)
  #   $ bundle exec rake tasks:change_organization_assigned_to[HearingTask,1,2,12,13,14,15,16]"
  # Assign all HearingTasks matching passed ids and assigned to org with id 1 to org with id 2 (execute)
  #   $ bundle exec rake tasks:change_organization_assigned_to[HearingTask,1,2,false,12,13,14,15,16]"
  desc "change the user or organization that active tasks are assigned to"
  task :change_organization_assigned_to, [
    :task_type, :from_assigned_to_id, :to_assigned_to_id, :dry_run
  ] => :environment do |_, args|
    logger_tag = "rake tasks:change_organization_assigned_to"
    Rails.logger.tagged(logger_tag) do
      Rails.logger.info("Invoked with: #{args.to_a.join(', ')}")
    end

    extras = args.extras
    dry_run = args.dry_run&.to_s&.strip&.upcase != "FALSE"
    if dry_run && args.dry_run.to_i > 0
      extras.unshift(args.dry_run)
    end

    if dry_run
      puts "*** DRY RUN"
      puts "*** pass 'false' as the fourth argument to execute"
    end

    task_class = Object.const_get(args.task_type)
    fail InvalidTaskType, "#{task_class.name} is not a valid Task type!" unless Task.descendants.include?(task_class)

    from_id = args.from_assigned_to_id.to_i
    to_id = args.to_assigned_to_id.to_i

    [from_id, to_id].each do |check_id|
      fail InvalidOrganization, "No organization with id #{check_id}!" if Organization.find_by(id: check_id).blank?
    end

    from_organization = Organization.find(from_id)
    to_organization = Organization.find(to_id)

    target_tasks = if extras.any?
                     task_class.where(id: extras, assigned_to: from_organization)
                   else
                     task_class.where(assigned_to: from_organization)
                   end

    if target_tasks.count == 0
      fail NoTasksToChange, "There aren't any #{task_class.name}s assigned " \
                            "to #{from_organization.name} available to change."
    end

    ids = target_tasks.map(&:id).sort
    change = dry_run ? "Would change" : "Changing"
    revert = dry_run ? "Would revert" : "Revert"
    message = "#{change} assignee of #{target_tasks.count} #{task_class.name}s with ids #{ids.join(', ')} " \
              "from #{from_organization.name} to #{to_organization.name}"
    puts message
    puts "#{revert} with: bundle exec rake tasks:change_organization_assigned_to" \
         "[#{task_class.name},#{to_id},#{from_id},false,#{ids.join(',')}]"

    if !dry_run
      Rails.logger.tagged(logger_tag) { Rails.logger.info(message) }
      target_tasks.update_all(assigned_to_id: to_id)
    end
  end

  # usage:
  # Reassign all tasks assigned to a user with an id of 1 (dry run)
  #   $ bundle exec rake tasks:reassign_from_user[1]"
  # Reassign all tasks assigned to a user with an id of 1 (execute)
  #   $ bundle exec rake tasks:reassign_from_user[1,false]"
  desc "reassign all tasks assigned to a user"
  task :reassign_from_user, [:user_id, :dry_run] => :environment do |_, args|
    Rails.logger.tagged("rake tasks:reassign_from_user") { Rails.logger.info("Invoked with: #{args.to_a.join(', ')}") }
    dry_run = args.dry_run&.to_s&.strip&.upcase != "FALSE"

    if dry_run
      puts "*** DRY RUN"
      puts "*** pass 'false' as the second argument to execute"
    end

    user = User.find(args.user_id)
    target_tasks = Task.open.includes(:parent).where(assigned_to_type: User.name, assigned_to_id: user.id)

    # Check for tasks in a bad state as outlined in
    # department-of-veterans-affairs/caseflow/blob/4fd949f3fb77c0aa0ec2854a3e5310a320aecd03/docs/11811_tech_spec.md
    ensure_user_has_tasks(target_tasks)
    ensure_all_tasks_have_parents(target_tasks)
    ensure_all_org_parent_tasks_have_same_type(target_tasks)
    ensure_all_user_parent_tasks_have_different_type(target_tasks)
    ensure_all_judge_assign_tasks_are_child_free(target_tasks)
    ensure_all_judge_review_tasks_have_child_attorney_tasks(target_tasks)
    ensure_all_judge_review_tasks_have_new_judge(target_tasks, user.css_id)

    ActiveRecord::Base.multi_transaction do
      reassign_judge_assign_tasks(target_tasks.where(type: JudgeAssignTask.name), dry_run)
      reassign_judge_review_tasks(target_tasks.where(type: JudgeDecisionReviewTask.name), user.css_id, dry_run)
      tasks_with_org_parents = target_tasks
        .where.not(type: [JudgeAssignTask.name, JudgeDecisionReviewTask.name])
        .where("parents_tasks.assigned_to_type = ?", Organization.name)
        .pluck("tasks.id, parents_tasks.assigned_to_type")
      reassign_tasks_with_parent_org_tasks(tasks_with_org_parents.map(&:first), dry_run)
      tasks_with_user_parents = target_tasks
        .where("parents_tasks.assigned_to_type = ?", User.name)
        .pluck("tasks.id, parents_tasks.assigned_to_type")
      reassign_tasks_with_parent_user_tasks(tasks_with_user_parents.map(&:first), dry_run)
    end
  end

  def ensure_user_has_tasks(target_tasks)
    fail NoTasksToReassign, "There aren't any open tasks assigned to this user." if target_tasks.count == 0
  end

  def ensure_all_tasks_have_parents(target_tasks)
    tasks_with_no_parent_ids = target_tasks.where(parent_id: nil).pluck(:id)

    if tasks_with_no_parent_ids.count > 0
      fail InvalidTaskParent, "Open tasks (#{tasks_with_no_parent_ids.join(', ')}) " \
                              "assigned to User #{user.id} have no parent task"
    end
  end

  def ensure_all_org_parent_tasks_have_same_type(target_tasks)
    tasks_with_org_parents_of_mismatched_type = target_tasks
      .where.not(type: [JudgeAssignTask.name, JudgeDecisionReviewTask.name])
      .where("parents_tasks.assigned_to_type = ? AND parents_tasks.type != tasks.type", Organization.name)
      .pluck("tasks.id, parents_tasks.assigned_to_type, parents_tasks.type")

    if tasks_with_org_parents_of_mismatched_type.count > 0
      fail InvalidTaskParent, "Open tasks (#{tasks_with_org_parents_of_mismatched_type.map(&:first).join(', ')}) " \
                              "assigned to User #{user.id} have parent task assigned to an organization but has a " \
                              "different task type"
    end
  end

  def ensure_all_user_parent_tasks_have_different_type(target_tasks)
    tasks_with_user_parents_of_same_type = target_tasks
      .where("parents_tasks.assigned_to_type = ? AND parents_tasks.type = tasks.type", User.name)
      .pluck("tasks.id, parents_tasks.assigned_to_type, parents_tasks.type")

    if tasks_with_user_parents_of_same_type.count > 0
      fail InvalidTaskParent, "Open tasks (#{tasks_with_user_parents_of_same_type.map(&:first).join(', ')}) " \
                              "assigned to User #{user.id} have parent task assigned to a user but has the same type"
    end
  end

  def ensure_all_judge_assign_tasks_are_child_free(target_tasks)
    open_children_of_tasks = Task.open.where(parent_id: target_tasks.where(type: JudgeAssignTask.name).pluck(:id))
    if open_children_of_tasks.count > 0
      fail InvalidTaskParent, "JudgeAssignTasks have open children (#{open_children_of_tasks.pluck(:id).join(', ')})"
    end
  end

  def ensure_all_judge_review_tasks_have_child_attorney_tasks(target_tasks)
    judge_review_task_ids = target_tasks.where(type: JudgeDecisionReviewTask.name).pluck(:id)
    open_children_of_tasks = AttorneyTask.open.where(parent_id: judge_review_task_ids)
    if judge_review_task_ids.sort != open_children_of_tasks.pluck(:parent_id).sort
      fail InvalidTaskParent, "JudgeDecisionReviewTasks " \
                              "(#{(judge_review_task_ids - open_children_of_tasks.pluck(:parent_id)).join(', ')}) " \
                              "have no open child attorney tasks"
    end
  end

  def ensure_all_judge_review_tasks_have_new_judge(target_tasks, old_judge_team_name)
    judge_review_task_ids = target_tasks.where(type: JudgeDecisionReviewTask.name).pluck(:id)
    child_attorney_tasks = AttorneyTask.not_cancelled.where(parent_id: judge_review_task_ids)
    new_judges_for_task = child_attorney_tasks.map do |atty_task|
      [
        atty_task.id,
        atty_task.assigned_to.organizations.where.not(name: old_judge_team_name).find_by(type: JudgeTeam.name)&.name
      ]
    end
    tasks_without_judges = new_judges_for_task.select { |task| task.second.nil? }
    if tasks_without_judges.count > 0
      fail InvalidTaskAssignee, "AttorneyTasks (#{tasks_without_judges.map(&:first).join(', ')}) assignee does " \
                                "not belong to a judge team with an active judge"
    end
  end

  def reassign_judge_assign_tasks(tasks, dry_run)
    task_ids = tasks.pluck(:id)
    cancel = dry_run ? "Would cancel" : "Cancelling"
    create = dry_run ? "create" : "creating"
    message = "#{cancel} #{task_ids.count} JudgeAssignTasks with ids #{task_ids.join(', ')} and #{create} " \
              "#{task_ids.count} DistributionTasks"
    puts message

    if !dry_run
      Rails.logger.tagged("rake tasks:reassign_from_user") { Rails.logger.info(message) }
      tasks.each do |task|
        DistributionTask.create!(appeal: task.appeal, parent: task.appeal.root_task)
        task.update!(status: Constants.TASK_STATUSES.cancelled)
      end
    end
  end

  def reassign_judge_review_tasks(tasks, old_judge_team_name, dry_run)
    task_ids = tasks.pluck(:id)
    cancel = dry_run ? "Would cancel" : "Cancelling"
    message = "#{cancel} #{task_ids.count} JudgeDecisionReviewTasks with ids #{task_ids.join(', ')} and move " \
              "#{task_ids.count} AttorneyTasks to new JudgeDecisionReviewTasks assigned to the attorney's new judge"
    puts message

    if !dry_run
      Rails.logger.tagged("rake tasks:reassign_from_user") { Rails.logger.info(message) }
      tasks.each do |task|
        atty_task = task.children_attorney_tasks.not_cancelled.order(:assigned_at).last
        new_supervising_judge = atty_task.assigned_to.organizations
          .where.not(name: old_judge_team_name)
          .find_by(type: JudgeTeam.name).judge
        task.reassign({ assigned_to_type: User.name, assigned_to_id: new_supervising_judge.id }, new_supervising_judge)
      end
    end
  end

  def reassign_tasks_with_parent_org_tasks(task_ids, dry_run)
  end

  def reassign_tasks_with_parent_user_tasks(task_ids, dry_run)
  end

  def reassign_automatically_assign_org_tasks(tasks, org)
  end
end
