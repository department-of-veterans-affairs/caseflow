# Backfill a HearingTask as parent of a ScheduleHearingTask and HoldHearingTask
# for Legacy Appeals.
#
# If an appeal has multiple ScheduleHearingTasks we group them by created_at and create
# one HeearingTask for each appeal/date combination.
#
# Author: OAR
# Date:   Feb 19, 2019
#

legacy_sched_hear_tasks = Task
  .where("(type='ScheduleHearingTask' OR type='HoldHearingTask') AND appeal_type='LegacyAppeal'")
  .select do |task|
  task.parent.type == "RootTask"
end
puts "Total HoldHearing or ScheduleHearing Tasks with RootTask as parent: #{legacy_sched_hear_tasks.size}"

tasks_grouped_by_appeal_and_date = legacy_sched_hear_tasks.group_by do |task|
  "#{task.appeal.id}-#{task.created_at.strftime('%Y-%m-%d')}"
end

puts tasks_grouped_by_appeal_and_date.inspect

tasks_grouped_by_appeal_and_date.each do |grouping, tasks|
  puts "Processing grouping #{grouping}"

  root_parent = tasks[0].parent
  hearing_task_status = "completed"

  hearing_task = HearingTask.create!(appeal: root_parent.appeal,
                                     assigned_to: Bva.singleton,
                                     status: hearing_task_status)

  tasks.each do |task|
    hearing_task_status = "on_hold" if task.status != "completed"
    task.parent = hearing_task
    task.save!
  end

  hearing_task.parent = root_parent
  hearing_task.status = hearing_task_status
  hearing_task.save!
end
