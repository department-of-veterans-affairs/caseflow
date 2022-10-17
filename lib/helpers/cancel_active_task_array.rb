# frozen_string_literal: true

# These steps will cancel ALL Tasks for a particular task type;
# for a user based upon assigned_to_id where not completed or cancelled.
module WarRoom
    class CancelActiveTaskArray
        def run(assigned_to_id, task_type)
        # set current user
        RequestStore[:current_user] = OpenStruct.new(ip_address: "127.0.0.1",
                                                     station_id: "283", css_id: "CSFLOW", regional_office: "DSUSER")
        # Sets the id of user or organization.
        user = assigned_to_id.to_i
        puts("Checking for a user or organization...")
  
        # Show the user if found.
        if User.find_by_id(user).nil?
        end
        # Show the organization if found.
        if !Organization.find_by_id(user).nil?
        else
          puts("Unable to find organization #{user} based upon Organization.find_by_id.")
        end
        # Checks if the assigned_to_id is found in the User or organization table
        if !User.find_by_id(user).nil? || !Organization.find_by_id(user).nil?
        else
          puts("Unable to find user or organization by the assigned_to_id of #{user}")
          fail Interrupt
        end
        # If a assigned to ID is found, this Checks to see if task type exists in the task table.
        # Checks if the user or organization has tasks in general.
        if (!User.find_by_id(user).nil? || Organization.find_by_id(user).nil?) &&
           Task.where(assigned_to_id: user, type: task_type).nil? == true
          puts("Unable to find tasks #{task_type} that were assigned to that User ID of #{user}...")
          fail Interrupt
        end
        # Checks that the assigned_to have the specified task type
        if Task.where(assigned_to_id: user, task: task_type).nil?
          puts("Unable to find task type. Have you checked the Metabase
                  task table for task type for specified user or organization
                  ? Aborting...")
          fail Interrupt
        end
        # Find all of the task types for that user or org, to be
        # cancelled that shows up within the appeal
        # as a "Status" of "assigned", "in_progress", or "on_hold"
        array_task_ids = Task.where(assigned_to_id: user,
                                    type: task_type, status: %w[on_hold in_progress assigned])
        puts(array_task_ids.to_s)
        if array_task_ids.empty?
          puts("Unable to establish array of the task type
                      and respective task ids. Aborting...")
          puts("Array is maybe empty")
          puts("Total count is #{array_task_ids.count}")
          fail Interrupt
        end
        puts("Warning: Total count is #{array_task_ids.count} is estimated to change
                  unless associated, complex, or dependent before or after tasks methods
                  related to other tasks")
        # Cancels the task array from the array_task_ids by the task find by
        array_task_ids = Task.where(assigned_to_id: user, type: task_type, status: %w[on_hold in_progress assigned])
        RequestStore[:current_user] = User.system_user
        array_task_ids.update(status: Constants.TASK_STATUSES.cancelled,
                              updated_at: Time.zone.now, cancelled_by_id: RequestStore[:current_user]&.id)
        puts "Task #{array_task_ids} completed"
    end
    end
end
