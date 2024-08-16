# frozen_string_literal: true

class HearingUpdateForm < BaseHearingUpdateForm
  # VA Notify Hooks
  prepend DocketHearingPostponed
  prepend DocketHearingWithdrawn
  prepend DocketHearingHeld

  attr_accessor :advance_on_docket_motion_attributes,
                :evidence_window_waived, :hearing_issue_notes_attributes,
                :transcript_sent_date, :transcription_attributes

  protected

  def update_hearing
    Transcription.find_or_create_by(hearing: hearing) unless transcription_attributes.blank?
    # a new HearingLocation is created here if hearing_location_attributes is present
    hearing.update!(hearing_updates)
    update_advance_on_docket_motion unless advance_on_docket_motion_attributes.blank?
  end

  def hearing_updated?
    super || advance_on_docket_motion_attributes.present?
  end

  private

  # Checks the scheduled_time_string value and returns the formatted
  # time in %H:#M
  # @return [String]
  def processed_scheduled_time
    return nil if scheduled_time_string.blank?

    Time.strptime(
      scheduled_time_string.split(" ").take(2).join(" "), "%I:%M %p"
    ).strftime("%H:%M")
  end

  # Checks the scheduled_time_string value and returns the formatted
  # datetime from HearingDatetimeService#prepare_time_for_storage
  # @return [nil] if scheduled_time_string or the existing value is blank
  # @return [Object] DateTime object
  def processed_scheduled_datetime
    return nil if scheduled_time_string.blank? || hearing.scheduled_datetime.blank?

    scheduled_date = hearing.hearing_day.scheduled_for.strftime("%Y-%m-%d")
    HearingDatetimeService.prepare_time_for_storage(
      date: scheduled_date,
      time_string: scheduled_time_string
    )
  end

  def update_advance_on_docket_motion
    AdvanceOnDocketMotion.create_or_update_by_appeal(
      hearing.appeal,
      advance_on_docket_motion_attributes.merge(user: RequestStore[:current_user])
    )
  end

  def after_update_hearing
    if virtual_hearing_created?
      hearing.appeal.update!(
        changed_hearing_request_type: Constants.HEARING_REQUEST_TYPES.virtual
      )
    elsif virtual_hearing_cancelled?
      hearing.appeal.update!(
        changed_hearing_request_type: hearing.original_request_type
      )
    end
  end

  # rubocop:disable Metrics/MethodLength
  def hearing_updates
    {
      bva_poc: bva_poc,
      disposition: disposition,
      evidence_window_waived: evidence_window_waived,
      hearing_issue_notes_attributes: hearing_issue_notes_attributes,
      hearing_location_attributes: hearing_location_attributes,
      hold_open: hold_open,
      judge_id: judge_id,
      military_service: military_service,
      notes: notes,
      prepped: prepped,
      representative_name: representative_name,
      room: room,
      scheduled_time: processed_scheduled_time,
      scheduled_datetime: processed_scheduled_datetime,
      summary: summary,
      transcript_requested: transcript_requested,
      transcript_sent_date: transcript_sent_date,
      transcription_attributes: transcription_attributes,
      witness: witness,
      email_recipients_attributes: email_recipients_attributes
    }.compact
  end
  # rubocop:enable Metrics/MethodLength
end
