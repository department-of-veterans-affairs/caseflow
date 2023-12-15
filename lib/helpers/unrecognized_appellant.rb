# frozen_string_literal: true

module WarRoom
  class UnrecognizedAppellant
    def self.run(dispatch_task_id)
      RequestStore[:current_user] = WarRoom.user

      ec = EstablishClaim.find(dispatch_task_id)
      la = ec.appeal

      return false unless la.veteran.nil?

      # Issues are printed for ticketing information
      iss = la.issues
      puts "===============ISSUES==============="
      puts((iss.count > 0) ? iss : "No issues for this appeal")
      puts "===================================="

      # Temporarily unblock the user by unassigning the task from the user and putting it
      # back to the bottom of the queue of dispatch tasks to get assigned
      # by setting the created_at time to now we put the task to the end of the queue because
      # the tasks are sorted oldest to newest
      ec.update!(user_id: nil, assigned_at: nil, started_at: nil, created_at: Time.zone.now, aasm_state: "unassigned")

      # Get information about the appeal for the dispatch task and pass it along to OAR
      # This information is sent to Jennifer.Schleicher@va.gov in an encrypted email
      veteran_info = {
        vacols_appeal_id: la.vacols_id,
        veteran_name: [la.veteran_first_name,
                       la.veteran_middle_initial,
                       la.veteran_last_name,
                       la.veteran_name_suffix].compact.join(" "),
        veteran_file_number: la.veteran_file_number
      }
      puts veteran_info
      veteran_info
    end

    def self.run_complete(dispatch_task_id)
      RequestStore[:current_user] = WarRoom.user

      ec = EstablishClaim.find(dispatch_task_id)
      la = ec.appeal

      return "Veteran was not nil." unless la.veteran.nil?

      # Issues are printed for ticketing information
      iss = la.issues
      puts "===============ISSUES==============="
      puts((iss.count > 0) ? iss : "No issues for this appeal")
      puts "===================================="

      return "User id was not nil." unless ec.user_id.nil?

      # Unblock the user by completing the task
      ec.update!(aasm_state: "completed",
                 comment: "Task has been completed by Caseflow dev team as per instruction by OAR")

      # Get information about the appeal for the dispatch task and pass it along to OAR
      # This information is sent to Jennifer.Schleicher@va.gov in an encrypted email
      veteran_info = {
        vacols_appeal_id: la.vacols_id,
        veteran_name: [la.veteran_first_name,
                       la.veteran_middle_initial,
                       la.veteran_last_name,
                       la.veteran_name_suffix].compact.join(" "),
        veteran_file_number: la.veteran_file_number
      }
      puts veteran_info
      veteran_info
    end
  end
end
