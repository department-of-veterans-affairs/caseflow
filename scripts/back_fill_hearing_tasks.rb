# Backfill a HearingTask as parent of a ScheduleHearingTask and HoldHearingTask
# for Legacy Appeals.
#
# Author: OAR
# Date:   Feb 19, 2019
#

legacy_sched_hear_tasks = Task.where("type='ScheduleHearingTask' AND appeal_type='LegacyAppeal'").select do |task|
  task.parent.type == "RootTask"
end
puts "Total ScheduleHearingTasks to be relinked: #{legacy_sched_hear_tasks.size}"

legacy_sched_hear_tasks.each do |task|
  hearing_task = HearingTask.create!(appeal: task.parent.appeal, assigned_to: Bva.singleton)

  # Traverse through all the children for the task parent, which is
  # the root task for the appeal (see query to identify the ScheduleHearinTasks)
  root_parent = task.parent
  hearing_task_status = "completed"
  root_parent.children.each do |child|
    next unless child.type == "ScheduleHearingTask" || child.type == "HoldHearingTask"

    hearing_task_status = "on_hold" if child.status != "completed"
    child.parent = hearing_task
    child.save!
  end

  hearing_task.parent = root_parent
  hearing_task.status = hearing_task_status
  hearing_task.save!
end
