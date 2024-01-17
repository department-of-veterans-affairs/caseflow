# frozen_string_literal: true

class TranscriptionTransaction < CaseflowRecord
  include BelongsToPolymorphicAppealConcern
  belongs_to_polymorphic_appeal :appeal
  belongs_to :transcriptions
  belongs_to :transcript
  belongs_to :docket

  # Upload audio files
  def upload_audio_transcript
    nil
  end

  # Upload raw VTT files
  def upload_raw_transcript
    nil
  end
end
