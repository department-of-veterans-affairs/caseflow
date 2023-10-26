# frozen_string_literal: true

# Build out Decision Review change history objects and reports

class ClaimHistoryService
  attr_reader :business_line, :processed_task_ids,
              :processed_request_issue_ids, :processed_request_issue_update_ids,
              :processed_decision_issue_ids, :events

  def initialize(business_line = VhaBusinessLine.singleton, filters = {})
    @business_line = business_line
    @filters = parse_filters(filters)
    @processed_task_ids = Set.new
    @processed_request_issue_update_ids = Set.new
    @processed_decision_issue_ids = Set.new
    @processed_request_issue_ids = Set.new
    # TODO: Not sure if we care about this stuff or not
    @number_of_database_rows = 0
    @number_of_database_columns = 0
    @database_query_time = 0
    @event_generation_time = 0

    # TODO: Should this automatically build events on creation? Probably not since it could be pretty slow
    # Also should this be persisted or not. Might be a pretty good chunk of memory but idk
    @events = []
  end

  def build_events
    # puts "Generating change history events for the: #{business_line.name} business line"
    # TODO: filter processing?? Either here or in the controller
    all_data = []

    @database_query_time = measure_execution_time do
      all_data = business_line.change_history_rows(@filters)
    end
    # all_data = business_line.change_history_rows(@filters)

    reset_processing_attributes

    # Print the total number of columns
    # puts "Total Number of columns: #{all_data.nfields}"
    # puts "Total Number of rows: #{all_data.count}"
    @number_of_database_columns = all_data.nfields
    @number_of_database_rows = all_data.count

    # events_array = []
    @event_generation_time = measure_execution_time do
      all_data.entries.map do |change_data|
        process_request_issue_update_events(change_data)
        process_request_issue_events(change_data)
        process_task_events(change_data)
        process_decision_issue_events(change_data)
      end
    end
    # TODO: Should I still auto compact? or should I just leave nulls and let other classes deal with that
    # events_array.compact
    @events.compact
  end

  def event_stats
    {
      parsed_task_ids: @processed_task_ids,
      parsed_request_issue_ids: @processed_request_issue_ids,
      parsed_request_issue_update_ids: @processed_request_issue_update_ids,
      parsed_decision_issue_ids: @processed_decision_issue_ids,
      database_query_time: @database_query_time,
      event_generation_time: @event_generation_time,
      number_of_database_columns: @number_of_database_columns,
      number_of_database_rows: @number_of_database_rows
    }
  end

  private

  def parse_filters(filters)
    filters
  end

  def reset_processing_attributes
    @processed_task_ids.clear
    @processed_request_issue_update_ids.clear
    @processed_decision_issue_ids.clear
    @processed_request_issue_ids.clear
    @events.clear
    @number_of_database_rows = 0
    @number_of_database_columns = 0
    @database_query_time = 0
    @event_generation_time = 0
  end

  def process_request_issue_update_events(change_data)
    request_issue_update_id = change_data["request_issue_update_id"]

    if request_issue_update_id && !@processed_request_issue_update_ids.include?(request_issue_update_id)
      @processed_request_issue_update_ids.add(request_issue_update_id)
      @events.push(*ClaimHistoryEvent.create_issue_events(change_data))
    end
  end

  def process_task_events(change_data)
    task_id = change_data["task_id"]

    # Can a task id ever be null? Maybe if you have like 3 request issue update rows, but only 1 or 2 of request issues
    # TODO: Test this scenario
    if !@processed_task_ids.include?(task_id)
      @processed_task_ids.add(task_id)
      @events.push ClaimHistoryEvent.create_claim_creation_event(change_data)
      # TODO: Rename this later
      @events.push(*ClaimHistoryEvent.no_database_create_status_events(change_data))
    end
  end

  def process_request_issue_events(change_data)
    request_issue_id = change_data["actual_request_issue_id"]

    if request_issue_id && !@processed_request_issue_ids.include?(request_issue_id)
      @processed_request_issue_ids.add(request_issue_id)
      @events.push(ClaimHistoryEvent.create_add_issue_event(change_data))
    end
  end

  def process_decision_issue_events(change_data)
    decision_issue_id = change_data["decision_issue_id"]

    if decision_issue_id && !@processed_decision_issue_ids.include?(decision_issue_id)
      @processed_decision_issue_ids.add(decision_issue_id)
      @events.push ClaimHistoryEvent.create_completed_disposition_event(change_data)
    end
  end

  # For timing stuff
  def measure_execution_time
    start_time = Time.zone.now
    yield
    end_time = Time.zone.now
    end_time - start_time
  end
end
