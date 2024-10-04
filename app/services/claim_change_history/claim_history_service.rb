# frozen_string_literal: true

# :reek:TooManyInstanceVariables
class ClaimHistoryService
  attr_reader :business_line, :processed_task_ids,
              :processed_request_issue_ids, :processed_request_issue_update_ids,
              :processed_decision_issue_ids, :events, :filters
  attr_writer :filters

  TIMING_RANGES = %w[
    before
    after
    between
    last_7_days
    last_30_days
    last_365_days
  ].freeze

  def initialize(business_line = VhaBusinessLine.singleton, filters = {})
    @business_line = business_line
    @filters = filters.to_h
    @processed_task_ids = Set.new
    @processed_request_issue_update_ids = Set.new
    @processed_decision_issue_ids = Set.new
    @processed_request_issue_ids = Set.new
    @events = []
  end

  def build_events
    # Reset the instance attributes from the last time build_events was ran
    reset_processing_attributes

    all_data = business_line.change_history_rows(@filters)

    all_data.entries.each do |change_data|
      process_request_issue_update_events(change_data)
      process_request_issue_events(change_data)
      process_decision_issue_and_task_events(change_data)
      # Don't process task events outside of decision issues unless there are no decision issues
      process_task_events(change_data) unless change_data["task_status"] == "completed"
    end

    # Compact and sort in place to reduce garbage collection
    @events.compact!
    @events.sort_by! do |event|
      [
        event.task_id,
        event.event_type == :claim_creation ? 0 : 1,
        event.event_type == :completed ? 1 : 0,
        event.event_date
      ]
    end

    # This currently relies on the events being sorted before hand
    filter_events_for_last_action_taken!

    @events
  end

  private

  def reset_processing_attributes
    @processed_task_ids.clear
    @processed_request_issue_update_ids.clear
    @processed_decision_issue_ids.clear
    @processed_request_issue_ids.clear
    @events.clear
  end

  def save_events(new_events)
    filtered_events = matches_filter(new_events)

    if filtered_events.present?
      @events.push(*filtered_events)
    end
  end

  def matches_filter(new_events)
    # Days Waiting, Task ID, Task Status, and Claim Type are all filtered entirely by the business line DB query
    # The events, Issue types, dispositions, personnel, and facilities filters are partially filtered by DB query
    # and then further filtered below in this service class after the event has been created

    # Ensure that we always treat this as an array of events for processing
    filtered_events = ensure_array(new_events)
    # Go ahead and extract any nil events
    filtered_events = process_event_filter(filtered_events.compact)
    filtered_events = process_issue_type_filter(filtered_events)
    filtered_events = process_dispositions_filter(filtered_events)
    filtered_events = process_timing_filter(filtered_events)

    # These are mutally exclusive in the UI, but no technical reason why both can't be used together
    filtered_events = process_personnel_filter(filtered_events)
    filtered_events = process_facility_filter(filtered_events)

    filtered_events.compact
  end

  def process_event_filter(new_events)
    return new_events if @filters[:events].blank?

    new_events.select { |event| event && ensure_array(@filters[:events]).include?(event.event_type) }
  end

  def process_issue_type_filter(new_events)
    return new_events if @filters[:issue_types].blank?

    new_events.select { |event| event && ensure_array(@filters[:issue_types]).include?(event.issue_type) }
  end

  def process_dispositions_filter(new_events)
    return new_events if @filters[:dispositions].blank?

    new_events.select do |event|
      event && ensure_array(@filters[:dispositions]).include?(event.disposition) ||
        @filters[:dispositions].include?("Blank") && event.disposition.nil?
    end
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def process_timing_filter(new_events)
    return new_events unless @filters[:timing].present? && TIMING_RANGES.include?(@filters[:timing][:range])

    # Try to guess the date format from either a string or iso8601 date string object
    start_date, end_date = date_range_for_timing_filter
    start_date, end_date = parse_date_strings(start_date, end_date)

    new_events.select do |event|
      next unless event.event_date

      event_date = event.event_date.to_date
      (start_date.nil? || event_date >= start_date) && (end_date.nil? || event_date <= end_date)
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity

  def date_range_for_timing_filter
    {
      "before" => [nil, @filters[:timing][:start_date]],
      "after" => [@filters[:timing][:start_date], nil],
      "between" => [@filters[:timing][:start_date], @filters[:timing][:end_date]],
      "last_7_days" => [Time.zone.today - 6, today_with_1_day_buffer],
      "last_30_days" => [Time.zone.today - 29, today_with_1_day_buffer],
      "last_365_days" => [Time.zone.today - 364, today_with_1_day_buffer]
    }[@filters[:timing][:range]]
  end

  def today_with_1_day_buffer
    Time.zone.today + 1.day
  end

  # Date helpers for filtering
  def parse_date_strings(start_date, end_date)
    start_date = parse_date(start_date)
    end_date = parse_date(end_date)
    [start_date, end_date]
  end

  # Function to attempt to guess the date from the filter. Works for 11/1/2023 format and iso8601
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

    new_events.select { |event| ensure_array(@filters[:personnel]).include?(event.event_user_css_id) }
  end

  def process_facility_filter(new_events)
    return new_events if @filters[:facilities].blank?

    # Station ids are strings for some reason
    new_events.select { |event| ensure_array(@filters[:facilities]).include?(event.user_facility) }
  end

  def filter_events_for_last_action_taken!
    return nil unless @filters[:status_report_type].present? && @filters[:status_report_type] == "last_action_taken"

    # This currently assumes that the events will be sorted by task_id and event_date before this
    # Use slice_when to group events by task_id
    grouped_events = events.slice_when { |prev, curr| prev.task_id != curr.task_id }

    # Map each group to its last event
    filtered_events = grouped_events.map(&:last)

    @events = filtered_events
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

    if task_id && !@processed_task_ids.include?(task_id)
      @processed_task_ids.add(task_id)
      save_events(ClaimHistoryEvent.create_claim_creation_event(change_data))
      save_events(ClaimHistoryEvent.create_status_events(change_data))
    end
  end

  def process_request_issue_events(change_data)
    request_issue_id = change_data["request_issue_id"]

    if request_issue_id && !@processed_request_issue_ids.include?(request_issue_id)
      @processed_request_issue_ids.add(request_issue_id)
      save_events(ClaimHistoryEvent.create_add_issue_event(change_data))
    end
  end

  def process_decision_issue_and_task_events(change_data)
    decision_issue_id = change_data["decision_issue_id"]

    if decision_issue_id && !@processed_decision_issue_ids.include?(decision_issue_id)
      @processed_decision_issue_ids.add(decision_issue_id)
      save_events(ClaimHistoryEvent.create_completed_disposition_event(change_data))

      # Status events sometimes need disposition information so make sure it lines up
      # with a decision issue row in the database
      process_task_events(change_data)
    end
  end

  def ensure_array(variable)
    variable.is_a?(Array) ? variable : [variable]
  end
end
