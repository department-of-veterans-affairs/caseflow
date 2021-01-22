# frozen_string_literal: true

module HearingRequestTypeConcern
  extend ActiveSupport::Concern

  included do
    # Add Paper Trail configuration
    has_paper_trail only: [:changed_request_type], on: [:update]

    validates :changed_request_type,
              inclusion: {
                in: [
                  HearingDay::REQUEST_TYPES[:central],
                  HearingDay::REQUEST_TYPES[:video],
                  HearingDay::REQUEST_TYPES[:virtual]
                ],
                message: "changed request type (%<value>s) is invalid"
              },
              allow_nil: true
  end

  class InvalidChangedRequestType < StandardError; end

  # uses the paper_trail version on LegacyAppeal
  def latest_appeal_event
    TaskEvent.new(version: versions.last) if versions.any?
  end

  def original_hearing_request_type(readable: false)
    # Use the VACOLS value for LegacyAppeals otherwise use the closest regional office
    original_hearing_request_type = is_a?(LegacyAppeal) ? hearing_request_type : closest_regional_office

    # Format the request type into a symbol
    formatted_request_type = format_hearing_request_type(original_hearing_request_type)

    # Return the human readable request type or the symbol of request type
    readable ? LegacyAppeal::READABLE_HEARING_REQUEST_TYPES[formatted_request_type] : formatted_request_type
  end

  def current_hearing_request_type(readable: false)
    request_type = changed_request_type.presence || original_hearing_request_type

    # Format the request type into a symbol
    formatted_request_type = format_hearing_request_type(request_type)

    # Return the human readable request type or the symbol of request type
    readable ? LegacyAppeal::READABLE_HEARING_REQUEST_TYPES[formatted_request_type] : formatted_request_type
  end

  # # if `change_hearing_request` is populated meaning the hearing request type was changed, then return what the
  # # previous hearing request type was. Use paper trail event to derive previous type in the case the type was changed
  # # multple times.
  def previous_hearing_request_type(readable: false)
    diff = latest_appeal_event&.diff || {} # Example of diff: {"changed_request_type"=>[nil, "R"]}
    previous_hearing_request_type = diff["changed_request_type"]&.first

    request_type = previous_hearing_request_type.presence || original_hearing_request_type

    # Format the request type into a symbol
    formatted_request_type = format_hearing_request_type(request_type)

    # Return the human readable request type or the symbol of request type
    readable ? LegacyAppeal::READABLE_HEARING_REQUEST_TYPES[formatted_request_type] : formatted_request_type
  end

  private

  # rubocop:disable Metrics/CyclomaticComplexity
  def format_hearing_request_type(request_type)
    return nil if request_type.nil?

    case request_type
    when HearingDay::REQUEST_TYPES[:central], :central_office, :central
      is_a?(LegacyAppeal) ? :central_office : :central
    when :travel_board
      video_hearing_requested ? :video : :travel_board
    when HearingDay::REQUEST_TYPES[:virtual]
      :virtual
    else
      :video
    end
  end
  # rubocop:enable Metrics/CyclomaticComplexity
end
