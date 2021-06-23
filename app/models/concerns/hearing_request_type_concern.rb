# frozen_string_literal: true

module HearingRequestTypeConcern
  extend ActiveSupport::Concern

  included do
    # Add Paper Trail configuration
    has_paper_trail only: [:changed_hearing_request_type], on: [:update]

    validates :changed_hearing_request_type,
              inclusion: {
                in: [
                  HearingDay::REQUEST_TYPES[:central],
                  HearingDay::REQUEST_TYPES[:video],
                  HearingDay::REQUEST_TYPES[:virtual]
                ],
                message: "changed request type (%<value>s) is invalid"
              },
              allow_nil: true

    validates :original_hearing_request_type,
              inclusion: {
                in: %w[central central_office travel_board video virtual],
                message: "original request type (%<value>s) is invalid"
              },
              allow_nil: true
  end

  def last_converted_by
    if versions.any?
      versions.last.whodunnit.present? ? User.find(versions.last.whodunnit) : User.new
    end
  end

  def formatted_original_hearing_request_type
    return original_hearing_request_type.to_sym if original_hearing_request_type.present?

    # Use the VACOLS value for LegacyAppeals, otherwise use the closest regional office
    original = is_a?(LegacyAppeal) ? hearing_request_type : closest_regional_office
    # Format the request type into a symbol
    format_hearing_request_type(original)
  end

  def readable_original_hearing_request_type
    LegacyAppeal::READABLE_HEARING_REQUEST_TYPES[formatted_original_hearing_request_type]
  end

  def remember_original_hearing_request_type
    if original_hearing_request_type.blank?
      update!(original_hearing_request_type: formatted_original_hearing_request_type&.to_s)
    end
  end

  def current_hearing_request_type
    format_or_formatted_original_hearing_request_type(changed_hearing_request_type)
  end

  def readable_current_hearing_request_type
    LegacyAppeal::READABLE_HEARING_REQUEST_TYPES[current_hearing_request_type]
  end

  def readable_previous_hearing_request_type_for_task(task_id)
    return nil if task_id.blank?

    previous_request_type = previous_hearing_request_type_for_task(task_id)
    LegacyAppeal::READABLE_HEARING_REQUEST_TYPES[previous_request_type]
  end

  def readable_current_hearing_request_type_for_task(task_id)
    return nil if task_id.blank?

    current_request_type = current_hearing_request_type_for_task(task_id)
    LegacyAppeal::READABLE_HEARING_REQUEST_TYPES[current_request_type]
  end

  private

  def previous_hearing_request_type_for_task(task_id)
    format_or_formatted_original_hearing_request_type(changeset_at_index_for_task(task_id)&.first)
  end

  def current_hearing_request_type_for_task(task_id)
    format_or_formatted_original_hearing_request_type(changeset_at_index_for_task(task_id)&.last)
  end

  def changeset_at_index_for_task(task_id)
    request_type_index = tasks.where(
      type: "ChangeHearingRequestTypeTask",
      status: Constants.TASK_STATUSES.completed
    ).order(:id).map(&:id).index(task_id)
    return nil if request_type_index.blank?

    # support versions that were recorded before the column name changed
    versions[request_type_index].changeset["changed_hearing_request_type"] ||
      versions[request_type_index].changeset["changed_request_type"]
  end

  def format_or_formatted_original_hearing_request_type(request_type)
    if request_type.present?
      format_hearing_request_type(request_type)
    else
      formatted_original_hearing_request_type
    end
  end

  # rubocop:disable Metrics/CyclomaticComplexity
  def format_hearing_request_type(request_type)
    return nil if request_type.nil?

    case request_type
    when HearingDay::REQUEST_TYPES[:central], :central_office, :central
      is_a?(LegacyAppeal) ? :central_office : :central
    when HearingDay::REQUEST_TYPES[:travel]
      :travel_board
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
