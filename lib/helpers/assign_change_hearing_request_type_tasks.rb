# frozen_string_literal: true

module AssignChangeHearingRequestTypeTasks
  def self.process_appeals
    # set the cutoff date as the current date plus 11 days.
    cutoff_date = Time.zone.today + 11

    # cycle each appeal in database with a docket type of "hearing"
    Appeal.where(docket_type: "hearing").find_each do |appeal|
      if appeal.hearings.empty?
        assign_change_hearing_request_type_task(appeal)
      else
        # search the hearings in the appeal to find the open hearing day id
        hearing_day_id = find_open_hearing(appeal.hearings)

        # get the hearing day using the hearing day id
        hearing_day = HearingDay.find_by(id: hearing_day_id)

        # if the hearing day doesn't exist or within cutoff date, assign the change hearing task
        if hearing_day.nil?
          assign_change_hearing_request_type_task(appeal)

        elsif hearing_day.scheduled_for > cutoff_date
          assign_change_hearing_request_type_task(appeal)

        end
        end
    end

    puts("Processing appeals is now finished!")
  end

  def self.assign_change_hearing_request_type_task(appeal)
    # get an array of the representative ids that belong to the appeal
    tasks_assigned_to_appeal = appeal.tasks

    # get the schedule hearing tasks that are on the appeal
    schedule_hearing_tasks = tasks_assigned_to_appeal.select { |task| task.type == "ScheduleHearingTask" }

    # get the open schedule hearings tasks if there are multiple
    schedule_hearing_task = schedule_hearing_tasks.select(&:active?)
    # get the VSO user(s) assigned to the appeal
    vso_users_assigned_to_appeal = get_vso_users_assigned_to_appeal(tasks_assigned_to_appeal)

    vso_users_assigned_to_appeal.each do |vso_user|
      # check the VSO user(s) have the ChangeHearingRequestTypeTask
      # next if can_vso_user_change_hearing_request_type(vso_user.tasks)

      # testing
      # assign ChangeHearingRequestTypeTask to user with the root task being the schedule_hearing_task
      ChangeHearingRequestTypeTask.create!(
        appeal: appeal,
        assigned_to: vso_user,
        parent: schedule_hearing_task[0],
        created_at: Time.zone.now,
        assigned_at: Time.zone.now
      )
    end
  end

  def self.can_vso_user_change_hearing_request_type(vso_user_tasks)
    vso_user_tasks.each do |task|
      if task.type == "ChangeHearingRequestTypeTask"
        return true
      end
    end
    false
  end

  def self.find_open_hearing(appeal_hearings)
    # cycle the hearings and throw out the ones that have a disposition
    appeal_hearings.each do |hearing|
      # the disposition is nil, the open hearing has been found
      if hearing.disposition.nil?
        # get the hearing day id and return
        return hearing.hearing_day_id
      end
    end
  end

  def self.get_vso_users_assigned_to_appeal(tasks_assigned_to_appeal)
    vso_users_assigned_to_appeal = []
    # cycle the representatives
    tasks_assigned_to_appeal.each do |task|
      # see if the task is a user
      next unless task.assigned_to_type == "User"

      # get the rep id from each task
      id = task.assigned_to_id

      # get the representative by the id
      representative = User.find_by(id: id)

      # find VSO users and push to array
      next unless representative.roles.include? "VSO"

      vso_users_assigned_to_appeal.push(representative)
    end
    vso_users_assigned_to_appeal
  end
end
