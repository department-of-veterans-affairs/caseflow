# frozen_string_literal: true

class TranscriptionTransformer
  class FileConversionError < StandardError; end

  def initialize(transcription_file)
    @transcription_file = transcription_file
    @rtf_file_path = @transcription_file.tmp_location.gsub("vtt", "rtf")
  end

  def call
    File.open(@rtf_file_path, "w")
    @rtf_file_path
  end
end
