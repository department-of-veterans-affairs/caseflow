# Script to backfill HearingTaskAssociation data in production.
#
# Identify all HoldHearingTasks
# Check if their parent HearingTask has an existing HearingTaskAssociation entry
# Find hearing associated with HearingTask using appeal id
# Create HearingTaskAssociation with Hearing and HearingTask info
#
# Author: OAR
# Date:   Feb 19, 2019
#

hearing_tasks = Task.where(type: "HoldHearingTask").map(&:parent)

puts hearing_tasks.inspect

hearing_tasks.each do |task|
  hearing = if task.appeal_type == "LegacyAppeal"
              LegacyHearing.find_by(appeal_id: task.appeal_id)
            else
              Hearing.find_by(appeal_id: task.appeal_id)
            end

  HearingTaskAssociation.create!(hearing: hearing, hearing_task: task)
end
