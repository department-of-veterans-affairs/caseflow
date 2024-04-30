# frozen_string_literal: true

class Hearings::ZipAndUploadTranscriptionFilesJob < CaseflowJob
  def perform(hearing_lookup_hashes)
    hearing_lookup_hashes.each do |hearing_lookup_hash|
      @hearing = ALLOWED_HEARING_KLASSES[hearing_lookup_hash[:hearing_type]].find(hearing_lookup_hash[:hearing_id])
      tmp_file_paths = fetch_transcription_files
      zip_file_path = zip(tmp_file_paths)
      formatted_zip_path = rename_before_upload(zip_file_path)
      # will implement upload to s3 here in next ticket
      cleanup_tmp(tmp_file_paths + [formatted_zip_path])
    end
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

  def cleanup_tmp(file_paths)
    file_paths.each { |path| File.delete(path) if File.exist?(path) }
  end
end
