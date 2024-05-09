# frozen_string_literal: true

class Hearings::ZipAndUploadTranscriptionFilesJob < CaseflowJob
  include Hearings::EnsureCurrentUserIsSet

  queue_with_priority :low_priority

  attr_reader :tmp_files_to_cleanup

  class ZipFileUploadError < StandardError; end

  retry_on(TranscriptionFileUpload::FileUploadError, wait: :exponentially_longer) do |job, _exception|
    job.cleanup_tmp(job.tmp_files_to_cleanup)
    # this error will allow the TranscriptionPackage workflow to customize a response email
    fail ZipFileUploadError
  end

  def perform(hearing_lookup_hashes)
    @tmp_files_to_cleanup = []

    ensure_current_user_is_set

    hearing_lookup_hashes.each do |hearing_lookup_hash|
      @hearing = ALLOWED_HEARING_KLASSES[hearing_lookup_hash[:hearing_type]].find(hearing_lookup_hash[:hearing_id])
      tmp_file_paths = fetch_transcription_files
      zip_file_path = zip(tmp_file_paths)
      formatted_zip_path = rename_before_upload(zip_file_path)
      tmp_files_to_cleanup.push(*tmp_file_paths, formatted_zip_path)
      create_transcription_file_for_zip(formatted_zip_path)&.upload_to_s3!
    end
    cleanup_tmp(tmp_files_to_cleanup)
  end

  def cleanup_tmp(file_paths)
    file_paths&.each { |path| File.delete(path) if File.exist?(path) }
    Rails.logger.info("Cleaned up the following files from tmp: #{file_paths}")
  end

  private

  # Purpose: allow request params to interact with intended db tables only
  ALLOWED_HEARING_KLASSES = {
    Hearing.name => Hearing,
    LegacyHearing.name => LegacyHearing
  }.freeze

  TRANSCRIPTION_FILE_TYPES = %w(mp3 rtf).freeze

  def fetch_transcription_files
    files = @hearing.transcription_files.where(
      hearing_type: @hearing.class.to_s,
      file_type: TRANSCRIPTION_FILE_TYPES
    )
    files.map(&:fetch_file_from_s3!)
  end

  def zip(tmp_file_paths)
    zip_file_name = zip_file_location
    Zip::File.open(zip_file_name, create: true) do |zip_file|
      tmp_file_paths.each do |file_path|
        file_name = file_path.split("/").last
        zip_file.add(file_name, file_path)
      end
    end
    zip_file_name
  end

  def zip_file_location
    file_name = @hearing.docket_number + "_" + @hearing.id.to_s + "_" + @hearing.class.to_s + ".zip"
    File.join(Rails.root, "tmp", "transcription_files", "zip", file_name)
  end

  # Purpose: Appends hexadecimal checksum and date of creation to the name of the zip file
  #
  # Returns: String - the updated absolute file path
  def rename_before_upload(zip_file_path)
    new_path = zip_file_path.sub(".", "-#{xor_checksum(zip_file_path)}-#{format_creation_date(zip_file_path)}.")
    File.rename(zip_file_path, new_path)
    new_path
  end

  def xor_checksum(file_path)
    checksum = 0
    File.open(file_path, "rb") do |file|
      file.each_byte { |byte| checksum ^= byte }
    end
    checksum.to_s(16)
  end

  # Purpose: format zip file creation date as YYYYMMDD to use in the file name
  def format_creation_date(file_path)
    File.ctime(file_path).strftime("%Y%m%d")
  end

  def create_transcription_file_for_zip(file_path)
    file_name = file_path.split("/").last
    created_by_id = RequestStore[:current_user].id

    begin
      TranscriptionFile.create!(
        file_name: file_name,
        hearing_id: @hearing.id,
        hearing_type: @hearing.class.name,
        docket_number: @hearing.docket_number,
        file_type: "zip",
        created_by_id: created_by_id
      )
    rescue ActiveRecord::RecordInvalid => error
      Rails.logger.error "Failed to create transcription file: #{error.message}"
    end
  end
end
