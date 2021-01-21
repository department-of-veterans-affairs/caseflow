# frozen_string_literal: true

module AppealConcern
  extend ActiveSupport::Concern

  delegate :station_key, to: :regional_office

  def regional_office
    return nil if regional_office_key.nil?

    @regional_office ||= begin
                            RegionalOffice.find!(regional_office_key)
                         rescue RegionalOffice::NotFoundError
                           nil
                          end
  end

  def regional_office_name
    return if regional_office.nil?

    "#{regional_office.city}, #{regional_office.state}"
  end

  def closest_regional_office_label
    return if closest_regional_office.nil?

    return "Central Office" if closest_regional_office == "C"

    RegionalOffice.find!(closest_regional_office).name
  end

  def veteran_name
    veteran_name_object.formatted(:form)
  end

  def veteran_full_name
    veteran_name_object.formatted(:readable_full)
  end

  def veteran_fi_last_formatted
    veteran_name_object.formatted(:readable_fi_last_formatted)
  end

  def appellant_name
    if appellant_first_name
      [appellant_first_name, appellant_middle_initial, appellant_last_name].select(&:present?).join(" ")
    end
  end

  # JOHN S SMITH => John S Smith
  def appellant_fullname_readable
    appellant_name&.titleize
  end

  def appellant_last_first_mi
    # returns appellant name in format <last>, <first> <middle_initial>.
    if appellant_first_name
      name = "#{appellant_last_name}, #{appellant_first_name}"
      "#{name} #{appellant_middle_initial}." if appellant_middle_initial
    end
  end

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

  # TODO: this is named "veteran_name_object" to avoid name collision, refactor
  # the naming of the helper methods.
  def veteran_name_object
    FullName.new(veteran_first_name, veteran_middle_initial, veteran_last_name)
  end
end
