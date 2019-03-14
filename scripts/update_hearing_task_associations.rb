# frozen_string_literal: true
def update_non_existent_hearing_task_associations
  appeal_ids = HearingTask.where(appeal_type: LegacyAppeal.name)\
    .joins("JOIN legacy_appeals ON appeal_id = legacy_appeals.id")\
    .select("legacy_appeals.vacols_id").map { |a| a.vacols_id }

  hearings = appeal_ids.in_groups_of(1000, false).map do |group|
    hearings = VACOLS::CaseHearing.where(folder_nr: group, hearing_disp: nil)
  end.flatten

  logs = []

  hearings.each do |hearing|
    legacy_hearing = LegacyHearing.find_by(vacols_id: hearing.hearing_pkseq)

    if legacy_hearing.nil?
      logs << "no legacy_hearing for vacols hearing #{hearing.hearing_pkseq}"
      next
    end

    hearing_tasks = HearingTask
      .where(
        appeal: legacy_hearing.appeal,
        status: [Constants.TASK_STATUSES.on_hold]
      )

    next if hearing_tasks.count == 0

    hearing_task = hearing_tasks.first

    if hearing_task.hearing_task_association.nil?
      HearingTaskAssociation.create!(
        hearing: legacy_hearing,
        hearing_task: hearing_task
      )

      logs << "associated hearing_task #{hearing_task.id} with legacy_hearing #{legacy_hearing.id}"
    end
  end
end

def update_stale_hearing_task_associations
  hearing_task_associations = HearingTaskAssociation.all

  legacy_hearing_ids = hearing_task_associations.pluck(:hearing_id)
  vacols_ids = LegacyHearing.where(id: legacy_hearing_ids).pluck(:vacols_id)

  postponed_vacols_hearings = vacols_ids.in_groups_of(1000, false).map do |group|
    VACOLS::CaseHearing.where(hearing_disp: "P", hearing_pkseq: group)\
      .order("hearing_date")
  end.flatten

  new_vacols_hearings = VACOLS::CaseHearing.where(
    folder_nr: postponed_vacols_hearings.pluck(:folder_nr), hearing_disp: nil
  )

  new_hearing_task_hearings = new_vacols_hearings.map do |hearing|
    LegacyHearing.find_by(vacols_id: hearing.hearing_pkseq)
  end

  new_hearing_task_hearings.each do |hearing|
    hearing_task = HearingTask.find_by(appeal: hearing.appeal)
    fail if hearing_task.nil?

    old_hearing = hearing_task.hearing_task_association.hearing

    hearing_task.hearing_task_association.update(hearing: hearing)

    puts "update hearing task #{hearing_task.id} association from #{old_hearing&.id} to #{hearing.id}"
  end
end
