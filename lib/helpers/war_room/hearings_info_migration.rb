# frozen_string_literal: true

module WarRoom
  class HearingsInfoMigration
    # Migrates AMA hearings
    # rubocop:disable Metrics/AbcSize, Metrics/MethodLength
    def move_ama_hearing(hearing_uuid, appeal_uuid)
      RequestStore[:current_user] = User.system_user
      ActiveRecord::Base.transaction do
        appeal_type = "Appeal"
        hearing = Hearing.find_by_uuid(hearing_uuid)
        appeal = Appeal.find_by_uuid(appeal_uuid)
        if hearing.nil?
          fail "Invalid UUID. Hearing not found. Aborting..."
        end
        if appeal.nil?
          fail "Invalid UUID. Appeal not found. Aborting..."
        end

        hearing_task = most_recent_hearing_task(appeal.id, appeal_type)
        schedule_task = most_recent_schedule_hearing_task(appeal.id, appeal_type)
        if schedule_task.nil? || schedule_task.status == "completed" || schedule_task.status == "cancelled"
          hearing_task, schedule_task = create_tasks(appeal, "Appeal")
        end
        check_old_hearing_task_status(hearing, appeal_type)
        check_old_disposition_task_status(hearing, appeal_type)
        hearing.update!(appeal_id: appeal.id, updated_by_id: User.system_user.id)
        HearingTaskAssociation.find_by(hearing_id: hearing.id,
                                       hearing_type: "Hearing").update!(hearing_task_id: hearing_task.id)
        create_and_set_disposition_task(appeal, hearing, hearing_task)
        schedule_task.update!(status: "completed", closed_at: Time.zone.now,
                              assigned_to: User.find_by_id(User.system_user.id))
      end
    end

    # Move Legacy Hearings
    def move_legacy_hearing(hearing_vacols_id, appeal_vacols_id)
      RequestStore[:current_user] = User.system_user
      ActiveRecord::Base.transaction do
        appeal_type = "LegacyAppeal"
        hearing = LegacyHearing.find_by(vacols_id: hearing_vacols_id)
        appeal = LegacyAppeal.find_by(vacols_id: appeal_vacols_id)
        if hearing.nil?
          fail "Invalid VACOLS ID. Hearing not found. Aborting..."
        end
        if appeal.nil?
          fail "INVALID VACOLS ID. Appeal not found. Aborting..."
        end

        hearing_task = most_recent_hearing_task(appeal.id, appeal_type)
        schedule_task = most_recent_schedule_hearing_task(appeal.id, appeal_type)
        if schedule_task.nil? || schedule_task.status == "completed" || schedule_task.status == "cancelled"
          hearing_task, schedule_task = create_tasks(appeal, appeal_type)
        end
        check_old_hearing_task_status(hearing, appeal_type)
        check_old_disposition_task_status(hearing, appeal_type)
        hearing.update!(appeal_id: appeal.id, updated_by_id: User.system_user.id)
        VACOLS::CaseHearing.find_by(hearing_pkseq: hearing_vacols_id).update!(folder_nr: appeal_vacols_id)
        HearingTaskAssociation.find_by(hearing_id: hearing.id,
                                       hearing_type: "LegacyHearing").update!(hearing_task_id: hearing_task.id)
        create_and_set_disposition_task(appeal, hearing, hearing_task)
        schedule_task.update!(status: "completed", closed_at: Time.zone.now,
                              assigned_to: User.find_by_id(User.system_user.id))
      end
    end

    # rubocop:enable Metrics/AbcSize, Metrics/MethodLength
    # Find the most recent HearingTask
    def most_recent_hearing_task(appeal_id, appeal_type)
      HearingTask.where(appeal_id: appeal_id, appeal_type: appeal_type).order(created_at: :desc).first
    end

    # Find the most recent ScheduleHearingTask
    def most_recent_schedule_hearing_task(appeal_id, appeal_type)
      ScheduleHearingTask.where(appeal_id: appeal_id, appeal_type: appeal_type).order(created_at: :desc).first
    end

    # Puts the the parent DistributionTask on hold
    def put_distribution_task_on_hold(appeal, appeal_type)
      distribution_task = DistributionTask.find_by(appeal_id: appeal.id, appeal_type: appeal_type)
      distribution_task.update!(status: "on_hold", placed_on_hold_at: Time.zone.now)
      distribution_task
    end

    # Creates the HearingTask
    def create_hearing_task(create_args, parent)
      hearing_task = HearingTask.create!(**create_args, parent: parent)
      hearing_task.update!(status: "on_hold", placed_on_hold_at: Time.zone.now)
      hearing_task
    end

    # Checks if the HearingTask of the old appeal is on hold
    # It gets set to complete if it is
    def check_old_hearing_task_status(hearing, appeal_type)
      old_hearing_task = HearingTask.where(appeal_id: hearing.appeal.id,
                                           appeal_type: appeal_type).order(created_at: :desc).first
      if old_hearing_task.status == "on_hold"
        old_hearing_task.update!(status: "cancelled", closed_at: Time.zone.now, cancelled_by_id: User.system_user.id)
      end
    end

    def check_old_disposition_task_status(hearing, appeal_type)
      old_disposition_task = AssignHearingDispositionTask.where(appeal_id: hearing.appeal.id,
                                                                appeal_type: appeal_type).order(created_at: :desc).first
      old_disposition_task_not_completed = old_disposition_task.status != "completed"
      old_disposition_task_not_cancelled = old_disposition_task.status != "cancelled"
      if old_disposition_task && old_disposition_task_not_completed && old_disposition_task_not_cancelled
        old_disposition_task.update!(status: "cancelled", closed_at: Time.zone.now,
                                     cancelled_by_id: User.system_user.id)
      end
    end

    # Wrapper method for creating the tasks for the hearing task tree
    def create_tasks(appeal, appeal_type)
      create_args = { appeal: appeal,
                      assigned_to: User.find_by_id(User.system_user.id),
                      assigned_by_id: User.system_user.id }
      distribution_task = put_distribution_task_on_hold(appeal, appeal_type)
      hearing_task = create_hearing_task(create_args, distribution_task)
      schedule_task = ScheduleHearingTask.create!(**create_args, parent: hearing_task)
      [hearing_task, schedule_task]
    end

    # Creates the AssignHearingDispositionTask
    # If there is already a disposition the task is set to complete
    def create_and_set_disposition_task(appeal, hearing, hearing_task)
      disposition_task = AssignHearingDispositionTask.create!(
        assigned_to: Bva.singleton,
        assigned_by_id: User.system_user.id,
        parent: hearing_task,
        appeal: appeal
      )
      if hearing.disposition == "held" || hearing.disposition == "no_show"
        disposition_task.update!(status: "completed", closed_at: Time.zone.now)
      elsif hearing.disposition == "postponed" || hearing.disposition == "scheduled_in_error"
        disposition_task.update!(status: "cancelled", closed_at: Time.zone.now, cancelled_by_id: User.system_user.id)
      end
    end
  end
end
