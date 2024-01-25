# frozen_string_literal: true

require "webvtt"

# Job for converting VTT transcription files to RTF
class Hearings::RTFConversionJob < CaseflowJob
  queue_with_priority :low_priority

  # Sub folder name
  S3_FOLDER_NAME = "vaec-appeals-caseflow"

  def initialize
    @logs = ["\nHearings::RTFConversion Log"]
    @folder_name = (Rails.deploy_env == :prod) ? S3_FOLDER_NAME : "#{S3_FOLDER_NAME}-#{Rails.deploy_env}"
    super
  end

  def perform
    retreive_files_from_s3(files_waiting_for_conversion)
    raw_transcript(path)
  end

  # Get transcription files waiting for file conversion
  def files_waiting_for_conversion
    TranscriptionFile.where(date_converted: nil)
  end

  # The temporary location of vtt files after fetching from S3
  # Return the location of the file
  def output_location
    File.join(Rails.root, "tmp", "vtts", vtt_name)
  end

  # The name of the vtt file after fetching
  # Return the name of the vtt file
  def vtt_name
    Time.zone.now.strftime("%m_%d_%Y_%H_%M_%S") + ".vtt"
  end

  def convert_and_upload_files(paths)
    paths.each do |path|
      convert_to_rtf(raw_transcript(path))
    end
  end

  # Retrieve files from the s3 bucket
  # Return the list of newly made output paths
  def retreive_files_from_s3(files)
    paths = []
    files.pluck(:file_name).each do |file|
      s3_location = S3_FOLDER_NAME + "/" + file + ".vtt"
      S3Service.fetch_file(s3_location, output_location)
      paths.push(output_location)
    end

    paths
  end

  # The raw transcript after parsing vtt
  def raw_transcript(path)
    webvtt = WebVTT.read(path)
    webvtt
    # webvtt.cues.each do |cue|
    #   puts "identifier: #{cue.identifier}"
    #   puts "Start: #{cue.start}"
    #   puts "End: #{cue.end}"
    #   puts "Style: #{cue.style.inspect}"
    #   puts "Text: #{cue.text}"
    #   puts "--"
    # end
  end

  # Convert vtt file to rtf
  def convert_to_rtf(path)

  end

  # Create a transcription file record
  def create_transcription_file(file_name, appeal_id, docket_number, date_converted, created_by_id, file_status)

  end

  # Upload file to S3 bucket
  def upload_to_s3

  end

  # Create an xls file for errors
  def create_xls_file

  end

end
