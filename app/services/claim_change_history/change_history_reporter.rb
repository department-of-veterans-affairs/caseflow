# frozen_string_literal: true

class ChangeHistoryReporter
  attr_reader :events
  attr_reader :event_filters
  attr_reader :tasks_url

  CHANGE_HISTORY_CSV_COLUMNS = %w[
    Veteran\ File\ Number
    Claimant
    Task\ URL
    Current\ Claim\ Status
    Days\ Waiting
    Claim\ Type
    Facility
    Edit\ User\ Name
    Edit\ Date
    Edit\ Action
    Issue\ Type
    Issue\ Description
    Prior\ Decision\ Date
    Disposition
    Disposition\ Description
    Disposition\ Date
  ].freeze

  def initialize(events, tasks_url, event_filters = {})
    @events = events
    @event_filters = event_filters
    @tasks_url = tasks_url
  end

  def event_filter_headers
    @event_filters.to_a.flatten
  end

  def as_csv
    CSV.generate do |csv|
      csv << event_filter_headers
      csv << CHANGE_HISTORY_CSV_COLUMNS
      events.each do |event|
        event_columns = event.to_csv_array.flatten
        # Replace the url from the event with the domain url retrieved from the controller request
        event_columns[2] = [tasks_url, event.task_id].join
        csv << event_columns
      end
    end
  end
end
