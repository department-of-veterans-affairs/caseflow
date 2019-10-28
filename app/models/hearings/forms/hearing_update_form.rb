# frozen_string_literal: true

class HearingUpdateForm < BaseHearingUpdateForm

  attr_accessor :evidence_window_waived,
    :hearing_issue_notes_attributes,
    :transcript_sent_date,
    :transcription_attributes

  protected

  def update_hearing
    updates = {
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
      scheduled_time: scheduled_time_string,
      summary: summary,
      transcript_requested: transcript_requested,
      transcript_sent_date: transcript_sent_date,
      transcription_attributes: transcription_attributes,
      witness: witness
    }.compact

    ActiveRecord::Base.transaction do
      Transcription.find_or_create_by(hearing: hearing)
      hearing.update!(updates)
    end
  end
end
