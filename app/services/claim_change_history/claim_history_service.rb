# frozen_string_literal: true

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

    # Reset the instance attributes from the last time build_events was ran
    reset_processing_attributes

    @database_query_time = measure_execution_time do
      all_data = business_line.change_history_rows(@filters)
    end

    @number_of_database_columns = all_data.nfields
    @number_of_database_rows = all_data.count

    @event_generation_time = measure_execution_time do
      all_data.entries.map do |change_data|
        process_request_issue_update_events(change_data)
        process_request_issue_events(change_data)
        process_task_events(change_data)
        process_decision_issue_events(change_data)
      end
    end

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
    filters.with_indifferent_access
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

  def save_events(new_events)
    filtered_events = matches_filter(new_events)

    if filtered_events.present?
      @events.push(*filtered_events)
    end
  end

  def matches_filter(new_events)
    # Days Waiting, Task ID, Task Status, Issue Types, Dispositions, and Claim Type are all filtered
    # entirely by the business line DB queries
    # The personnel and facilities filters are partially filtered by DB queries and further filtered below

    # Ensure that we always treat this as an array of events for processing
    filtered_events = new_events.is_a?(Array) ? new_events : [new_events]
    # Go ahead and extract any nil events
    filtered_events = process_event_filter(filtered_events.compact)
    filtered_events = process_timing_filter(filtered_events)
    # These two should be mutally exclusive according to the AC but no technical reason why
    # they couldn't both be used simultaneously
    filtered_events = process_personnel_filter(filtered_events)
    filtered_events = process_facility_filter(filtered_events)

    filtered_events.compact
  end

  def process_event_filter(new_events)
    return new_events if @filters[:events].blank?

    new_events.select { |event| event && @filters[:events].include?(event.event_type) }
  end

  # TODO: I have no idea what the format of the date from the filter is going to be here
  def process_timing_filter(new_events)
    return new_events if @filters[:timing].blank?

    start_date, end_date = date_range_for_timing_filter
    start_date, end_date = parse_date_strings(start_date, end_date)

    new_events.select do |event|
      event_date = Date.parse(event.event_date)
      (start_date.nil? || event_date >= start_date) && (end_date.nil? || event_date <= end_date)
    end
  end

  def date_range_for_timing_filter
    {
      "before" => [nil, @filters[:timing][:start_date]],
      "after" => [@filters[:timing][:start_date], nil],
      "between" => [@filters[:timing][:start_date], @filters[:timing][:end_date]],
      "last 7 days" => [Time.zone.today - 6, Time.zone.today],
      "last 30 days" => [Time.zone.today - 29, Time.zone.today],
      "last 365 days" => [Time.zone.today - 364, Time.zone.today]
    }[@filters[:timing][:range]]
  end

  # Date helpers for filtering
  def parse_date_strings(start_date, end_date)
    start_date = parse_date(start_date)
    end_date = parse_date(end_date)
    [start_date, end_date]
  end

  # Function to attempt to guess the date from the filter. Works for 11/1/2023 format and iso8601
  # It's gross because it's using error handling for logic though.
  def parse_date(date)
    if date.is_a?(String)
      begin
        Date.strptime(date, "%m/%d/%Y")
      rescue ArgumentError
        Date.iso8601(date)
      end
    else
      date
    end
  end

  def process_personnel_filter(new_events)
    return new_events if @filters[:personnel].blank?

    new_events.select { |event| @filters[:personnel].include?(event.event_user_id) }
  end

  def process_facility_filter(new_events)
    return new_events if @filters[:facilities].blank?

    # TODO: Station ids are strings because I have no idea why. So filter needs to be string
    # Unless I force the history event to save it as a integer to the attribute. Which would be fine
    new_events.select { |event| @filters[:facilities].include?(event.user_facility) }
  end

  def process_request_issue_update_events(change_data)
    request_issue_update_id = change_data["request_issue_update_id"]

    if request_issue_update_id && !@processed_request_issue_update_ids.include?(request_issue_update_id)
      @processed_request_issue_update_ids.add(request_issue_update_id)
      save_events(ClaimHistoryEvent.create_issue_events(change_data))
    end
  end

  def process_task_events(change_data)
    task_id = change_data["task_id"]

    # Can a task id ever be null? Maybe if you have like 3 request issue update rows, but only 1 or 2 of request issues
    # TODO: Test this scenario
    if !@processed_task_ids.include?(task_id)
      @processed_task_ids.add(task_id)
      save_events(ClaimHistoryEvent.create_claim_creation_event(change_data))
      save_events(ClaimHistoryEvent.create_status_events(change_data))
    end
  end

  def process_request_issue_events(change_data)
    request_issue_id = change_data["actual_request_issue_id"]

    if request_issue_id && !@processed_request_issue_ids.include?(request_issue_id)
      @processed_request_issue_ids.add(request_issue_id)
      save_events(ClaimHistoryEvent.create_add_issue_event(change_data))
    end
  end

  def process_decision_issue_events(change_data)
    decision_issue_id = change_data["decision_issue_id"]

    if decision_issue_id && !@processed_decision_issue_ids.include?(decision_issue_id)
      @processed_decision_issue_ids.add(decision_issue_id)
      save_events(ClaimHistoryEvent.create_completed_disposition_event(change_data))
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
