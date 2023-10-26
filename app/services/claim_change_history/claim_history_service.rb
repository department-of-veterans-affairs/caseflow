# frozen_string_literal: true

# Build out Decision Review change history objects and reports

class ClaimHistoryService

  class << self
    def build_events(business_line = VhaBusinessLine.singleton, filters = {})
      # puts "Generating change history events for the: #{business_line.name} business line"
      # TODO: filter processing??
      all_data = business_line.change_history_rows(filters)

      # TODO: See if there's another way to do this.
      processed_task_ids = Set.new
      processed_request_issue_update_ids = Set.new
      processed_decision_issue_ids = Set.new
      processed_request_issue_ids = Set.new

      # Print the total number of columns
      # puts "Total Number of columns: #{all_data.nfields}"
      # puts "Total Number of rows: #{all_data.count}"

      events_array = []

      all_data.entries.map do |change_data|
        task_id = change_data["task_id"]
        request_issue_update_id = change_data["request_issue_update_id"]
        decision_issue_id = change_data["decision_issue_id"]
        request_issue_id = change_data["actual_request_issue_id"]

        if request_issue_update_id && !processed_request_issue_update_ids.include?(request_issue_update_id)
          processed_request_issue_update_ids.add(request_issue_update_id)
          events_array.push(*ChangeHistoryEvent.create_issue_events(change_data))
        end

        if request_issue_id && !processed_request_issue_ids.include?(request_issue_id)
          processed_request_issue_ids.add(request_issue_id)
          events_array.push(ChangeHistoryEvent.create_add_issue_event(change_data))
        end

        if !processed_task_ids.include?(task_id)
          processed_task_ids.add(task_id)
          events_array.push ChangeHistoryEvent.create_claim_creation_event(change_data)
          events_array.push(*ChangeHistoryEvent.no_database_create_status_events(change_data))
        end

        if decision_issue_id && !processed_decision_issue_ids.include?(decision_issue_id)
          processed_decision_issue_ids.add(decision_issue_id)
          events_array.push ChangeHistoryEvent.create_completed_disposition_event(change_data)
        end

        events_array
      end

      events_array.compact
    end
  end
end
