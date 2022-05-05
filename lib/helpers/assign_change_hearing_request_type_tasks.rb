# frozen_string_literal: true

class AssignChangeHearingRequestTypeTasks
  def process_appeals
    # set the cutoff date as the current date plus 11 days.
    cutoff_date = Time.zone.today + 11

    # cycle each appeal in database with a docket type of "hearing"
    Appeal.where(docket_type: "hearing").find_each do |appeal|
      # for testing
      puts("processing appeal #{appeal}")
      # search the hearings in the appeal to find the open hearing day id
      hearing_day_id = find_open_hearing(appeal.hearings)

      # get the hearing scheduled date using the hearing day id
      hearing_scheduled_date = HearingDay.find(id: hearing_day_id).scheduled_for

      if (hearing_scheduled_date > cutoff_date) || hearing_scheduled_date.nil?

        # get an array of the representative ids that belong to the appeal
        rep_ids_assigned_to_appeal = Task.where(appeal_id: appeal.id).assigned_to_id

        # get the VSO user(s) assigned to the appeal
        vso_users_assigned_to_appeal = get_VSO_users_assigned_to_appeal(rep_ids_assigned_to_appeal)

        vso_users_assigned_to_appeal.each do |vso_user|
          # check the VSO user(s) have the ChangeHearingRequestTypeTask
          next if can_vso_user_change_hearing_request_type(vso_user.tasks)

          # testing
          puts("User #{vso_user.full_name} assigned ChangeHearingRequestTypeTask")

          # assign ChangeHearingRequestTypeTask to user
          ChangeHearingRequestTypeTask.create!(
            appeal: appeal,
            assigned_to: vso_user,
            parent: self
          )
        end
      end
    end
  end

  def can_vso_user_change_hearing_request_type(vso_user_tasks)
    vso_user_tasks.each do |task|
      if task.type == "ChangeHearingRequestType"
        return true
      end
    end
    false
  end

  def find_open_hearing(appeal_hearings)
    # cycle the hearings and throw out the ones that have a disposition
    appeal_hearings.each do |hearing|
      # the disposition is nil, the open hearing has been found
      if hearing.disposition.nil?
        # get the hearing day id and return
        return hearing.hearing_day_id
      end
    end
  end

  def get_VSO_users_assigned_to_appeal(representative_ids)
    vso_users_assigned_to_appeal = []
    # cycle the representatives
    representative_ids.each do |id|
      # get the representative role
      representative = Users.where(id: id)

      # find VSO users
      if representative.roles == "VSO"
        vso_users_assigned_to_appeal.push(representative)
      end
    end
  end
end
