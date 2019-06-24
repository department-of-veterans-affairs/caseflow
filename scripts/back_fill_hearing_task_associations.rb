# frozen_string_literal: true

# Script to backfill HearingTaskAssociation data in production.
#
# Identify all DispositionTasks
# Check if their parent HearingTask has an existing HearingTaskAssociation entry
# Find hearing associated with HearingTask using appeal id
# Create HearingTaskAssociation with Hearing and HearingTask info
#
# Author: OAR
# Date:   Feb 19, 2019
#

# All DispositionTasks are for Legacy Appeals in prod. Total 156 as of AM Feb 25th 2019
hearing_tasks = Task.where(type: "AssignHearingDispositionTask", appeal_type: "LegacyAppeal").map(&:parent)

task_association_exists = 0
nbr_of_task_associations_created = 0
nbr_of_vacols_records_older_than_today = 0
nbr_of_vacols_recods_not_found = 0

hearing_tasks.each do |task|
  # check if HearingTask already has an entry in the
  # associations table.
  task_association = HearingTaskAssociation.find_by(hearing_task_id: task.id)
  task_association_exists += 1 if task_association
  next unless task_association.nil?

  # Get all legacy hearings for appeal id
  hearings = LegacyHearing.where(appeal_id: task.appeal_id)

  # Need to account for multiple hearings for an appeal. Must choose the one with
  # disposition of null.
  # Prod data shows that some vacols identifiers in LegacyHearing may not be present
  # any more in VACOLS.
  hearings.each do |hearing|
    vacols_hearing = VACOLS::CaseHearing.find(hearing.vacols_id)
    if vacols_hearing.hearing_disp.nil?
      if vacols_hearing.hearing_date >= Time.zone.today.beginning_of_day
        HearingTaskAssociation.create!(hearing: hearing, hearing_task: task)
        nbr_of_task_associations_created += 1
      else
        nbr_of_vacols_records_older_than_today += 1
      end
    end
  rescue ActiveRecord::RecordNotFound
    puts "No VACOLS hearing found for legacy hearing #{hearing.vacols_id}"
    nbr_of_vacols_recods_not_found += 1
  end
end

puts "Number of HearingTasks: #{hearing_tasks.size}"
puts "Nbr of Hearing Tasks already associated to Hearing: #{task_association_exists}"
puts "Nbr of VACOLS Hearings older than today's date: #{nbr_of_vacols_records_older_than_today}"
puts "Total task associations created: #{nbr_of_task_associations_created}"
puts "Legacy Hearings with no VACOLS hearing: #{nbr_of_vacols_recods_not_found}"
