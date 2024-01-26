# frozen_string_literal: true

class TranscriptionFile < CaseflowRecord
  include BelongsToPolymorphicAppealConcern
  belongs_to_polymorphic_appeal :appeal
  belongs_to :transcription
  belongs_to :docket

  # Upload audio files
  def upload_audio_transcript
    nil
  end

  # Upload raw VTT files
  def upload_raw_transcript
    nil
  end

  # Update transcription file status
  def update_file_status
    nil
  end

  # Download transcription files from S3
  def download_transcription_files
    nil
  end
end
