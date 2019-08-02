# frozen_string_literal: true

namespace :fixes do
  class NoStalledHearingTasksFound < StandardError; end

  # usage:
  # Activate all stalled HearingTasks by setting their ScheduleHearingTask child status to assigned
  #   $ bundle exec rake fixes:activate_stalled_hearing_tasks[0, false]
  # Activate only the first stalled HearingTask
  #   $ bundle exec rake fixes:activate_stalled_hearing_tasks[1, false]
  # Perform a dry run
  #   $ bundle exec rake fixes:activate_stalled_hearing_tasks[]
  desc "re-activate stalled HearingTasks"
  task :activate_stalled_hearing_tasks, [:limit, :dry_run] => :environment do |_, args|
    Rails.logger.tagged("rake fixes:activate_stalled_hearing_tasks") do
      Rails.logger.info("Invoked with: #{args.to_a.join(', ')}")
    end

    limit = args.limit&.to_i

    limited = (limit &.> 0)

    dry_run = args.dry_run&.to_s&.strip&.upcase != "FALSE"

    if dry_run
      puts "*** DRY RUN"
      puts "*** pass 'false' as the third argument to execute"
    end

    # find HearingTasks that
    # - are open
    # - are the only HearingTask on their appeal
    # - have no active descendants
    # - have a single child which is an on_hold ScheduleHearingTask with no open descendants
    target_tasks = HearingTask.open.order(:id).select do |task|
      task.appeal.tasks.where(type: HearingTask.name).count == 1 &&
        task.descendants.map(&:active?).exclude?(true) &&
        task.children.count == 1 &&
        task.children.first.type == ScheduleHearingTask.name &&
        task.children.first.status == Constants.TASK_STATUSES.on_hold &&
        (task.children.first.descendants - [task.children.first]).map(&:open?).exclude?(true)
    end

    target_tasks_found = target_tasks.count

    if limited
      target_tasks = target_tasks[0..limit - 1]
    end

    if target_tasks.count == 0
      fail NoStalledHearingTasksFound, "No stalled HearingTasks were found."
    end

    change = dry_run ? "Would update" : "Updating"
    message = "Found #{target_tasks_found} stalled HearingTasks. #{change} #{target_tasks.count} stalled " \
      "HearingTasks with IDs #{target_tasks.map(&:id).sort}!"
    puts message

    if !dry_run
      Rails.logger.tagged("rake fixes:activate_stalled_hearing_tasks") { Rails.logger.info(message) }
      target_tasks.each { |task| task.children.first.update!(status: Constants.TASK_STATUSES.assigned) }
    end
  end
end
