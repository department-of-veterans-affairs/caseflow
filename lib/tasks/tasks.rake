# frozen_string_literal: true

namespace :tasks do
  class InvalidTaskType < StandardError; end
  class InvalidOrganization < StandardError; end
  class NoTasksToChange < StandardError; end

  # usage:
  # Change all HoldHearingTasks to DispositionTasks (dry run)
  #   $ bundle exec rake tasks:change_type[HoldHearingTask,DispositionTask]"
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

  desc "change the user or organization that active tasks are assigned to"
  task :change_organization_assigned_to, [
    :task_type, :from_assigned_to_id, :to_assigned_to_id, :dry_run
  ] => :environment do |_, args|
    Rails.logger.tagged("rake tasks:change_organization_assigned_to") do
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
                     task_class.find(extras).select { |task| task.assigned_to_id = from_id }
                   else
                     task_class.all.where(assigned_to_type: "Organization", assigned_to_id: from_id)
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
      Rails.logger.tagged("rake tasks:change_organization_assigned_to") { Rails.logger.info(message) }
      target_tasks.each do |task|
        task.update!(assigned_to_id: to_id)
      end
    end
  end
end
