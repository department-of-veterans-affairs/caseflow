class TaskRemediation
    def self.reassign_by_task_id!(old_css_id_string, new_css_id_string, array_of_task_ids)
        #Set the current user so that Paper Trail can record the user that made changes
        RequestStore[:current_user] = User.system_user

        #Assign New User to variable
        new_user=User.find_by_css_id(new_css_id_string)

        #Assign all tasks.  If more than 1, seperate each task by a comma.  Ex. [1111,2222,3333]
        assigned_tasks = Task.where(id: array_of_task_ids)

        #Confirm Number of Tasks Being Reassigned matches the number of tasks displayed within the current user's assigned and on hold queue 
        #within Casflow UI
        puts "\n\n\n#{assigned_tasks.count} task(s) are being reassigned\n\n\n"

        #Task Counter Variable
        task_counter = 0

        #Loop through each task to update "assigned_to_id", "assigned_by_id", "updated_at" and log changes (PaperTrail will automatically record
        #a new "version" everytime a task uses the ".update!" method.  All changes from the update will be saved in the "Versions" Table.)
        assigned_tasks.each {|task| task.update!(assigned_to_id: new_user.id, assigned_by_id: User.system_user.id, updated_at: Time.zone.now) && task_counter += 1}

        #Display number of Tasks Reassigned
        puts "\n\n\n#{task_counter} task(s) successfully reassigned\n\n\n"
    end

    def self.reassign_by_appeal_uuid!(old_css_id_string, new_css_id_string, array_of_uuids_as_strings)
        #Set the current user so that Paper Trail can record the user that made changes
        RequestStore[:current_user] = User.system_user

        #Assign Old User to a variable
        old_user=User.find_by_css_id(old_css_id_string)
 
        #Assign New User to variable
        new_user=User.find_by_css_id(new_css_id_string)

        #Find appeals by their UUID and add them to array variable named 'appeals'.  Use a comma to separate UUIDs if there is more than one.
        #Ex. ["UUID", "UUID", "UUID"]
        appeals=Appeal.where(uuid: array_of_uuids_as_strings)

        #Declare variable 'all_tasks' as an empty array
        all_tasks = []

        #Iterate through each task within each appeal to get all the task ids and append those ids into the all_tasks array
        appeals.each {|appeal| appeal.tasks.each {|task| all_tasks.append(task.id)}}

        #Add all open tasks that were assigned to the old_user to array variable named 'assigned_tasks'
        assigned_tasks = Task.where(id: all_tasks, assigned_to: old_user).merge(Task.where.not(status: ["completed", "cancelled"]))

        #Confirm Number of Tasks Being Reassigned matches the number of tasks desired to be reassigned from within the current user's 
        #assigned and on hold queue within Casflow UI
        puts "\n\n\n#{assigned_tasks.count} task(s) found to be reassigned\n\n\n"

        #Task Counter Variable
        task_counter = 0

        #Loop through each task to update "assigned_to_id", "assigned_by_id", "updated_at" and log changes (PaperTrail will automatically record
        #a new "version" everytime a task uses the ".update!" method.  All changes from the update will be saved in the "Versions" Table.)
        assigned_tasks.each {|task| task.update!(assigned_to_id: new_user.id, assigned_by_id: User.system_user.id, updated_at: Time.zone.now) && task_counter += 1}
        
        #Display number of Tasks Reassigned
        puts "\n\n\n#{task_counter} task(s) successfully reassigned\n\n\n"
    end

    def
        self.bulk_task_reassignment!(old_css_id_string, new_css_id_string)
        #Set the current user so that Paper Trail can record the user that made changes
        RequestStore[:current_user] = User.system_user

        #Assign Old User to a variable
        old_user=User.find_by_css_id(old_css_id_string)
 
        #Assign New User to variable
        new_user=User.find_by_css_id(new_css_id_string)

        #Find all of the tasks that show up within the old user's queue (as well as any "on_hold" tasks that are NOT currently displayed in Queue)
        assigned_tasks = Task.where(assigned_to: old_user).merge(Task.where.not(status: ["completed", "cancelled"]))

        #Confirm Number of Tasks Being Reassigned matches the number of tasks displayed within the current user's queue in Casflow UI
        #Note: This number may be higher than what is shown in user's queue if user has Tasks that are "on_hold".  
        puts "\n\n\n#{assigned_tasks.count} task(s) are being reassigned\n\n\n"

        #Task Counter Variable
        task_counter = 0

        #Loop through each task to update "assigned_to_id", "assigned_by_id", "updated_at" and log changes (PaperTrail will automatically record
        #a new "version" everytime a task uses the ".update!" method.  All changes from the update will be saved in the "Versions" Table.)
        assigned_tasks.each {|task| task.update!(assigned_to_id: new_user.id, assigned_by_id: User.system_user.id, updated_at: Time.zone.now) && task_counter += 1}
    
        #Display number of Tasks Reassigned
        puts "\n\n\n#{task_counter} task(s) successfully reassigned\n\n\n"
    end

    def
        self.status_update!(task_id, new_status_string)
        #Set the current user so that Paper Trail can record the user that made changes
        RequestStore[:current_user] = User.system_user

        #Find task by task_id
        task=Task.find(task_id)

        #Confirm the Current Status of the Task
        puts "\n\n\nTask ID #{task.id} currently has a status of #{task.status}\n\n\n"

        #Update Status
        task.update!(status: new_status_string, updated_at: Time.zone.now)
    
        #Display New Status of Task to confirm
        puts "\n\n\nTask ID #{task.id} now has a status of #{task.status}\n\n\n"
    end
end


  