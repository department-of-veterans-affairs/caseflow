namespace :tasks do
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
        abort "#{check_class.name} is not a valid Task type!"
      end

      if check_class.descendants.count > 0
        puts "*WARNING* #{check_class.name} has #{check_class.descendants.count} descendants"
      end
    end

    target_tasks = if extras.any?
                     from_class.find(extras)
                   else
                     from_class.all
                   end

    if target_tasks.count == 0
      abort "There aren't any #{from_class.name}s available to change."
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
end
