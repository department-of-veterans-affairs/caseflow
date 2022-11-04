# frozen_string_literal: true

# These steps will cancel ALL Tasks for a particular task type;
# for a user based upon assigned_to_id where not completed or cancelled.
# rubocop:disable Metrics/MethodLength
# rubocop:disable Metrics/AbcSize
# rubocop:disable Metrics/CyclomaticComplexity
# rubocop:disable Metrics/PerceivedComplexity
module WarRoom
  class CancelActiveTaskArray
    def run(assigned_to_id, task_type)
      # set current user
      RequestStore[:current_user] = OpenStruct.new(ip_address: "127.0.0.1",
                                                   station_id: "283", css_id: "CSFLOW", regional_office: "DSUSER")
      # Sets the id of user
      user = assigned_to_id.to_i
      puts("print user #{user}")

      # If user not found fail interrupt
      if User.find_by_id(user).nil?
        puts("Unable to find user #{user} based upon User.find_by_id")
        fail Interrupt
      end

      # If organization not found fail interrupt
      if Organization.find_by_id(user).nil?
        puts("Unable to find organization #{user} based upon Organization.find_by_id")
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
      puts("array_task_ids #{array_task_ids}")

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
      puts("RequestStore[:current_user] #{RequestStore[:current_user]}")
      puts("User.system_user #{User.system_user}")
      RequestStore[:current_user] = User.system_user
      array_task_ids.update(status: Constants.TASK_STATUSES.cancelled,
                            updated_at: Time.zone.now, cancelled_by_id: RequestStore[:current_user].id)
      puts("Task #{array_task_ids} completed")
    end
  end
end
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/AbcSize
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/PerceivedComplexity
