# frozen_string_literal: true

module Hearings
  class ZipAndUploadTranscriptionFilesJob < CaseflowJob
    include EnsureCurrentUserIsSet

    queue_as :low_priority
    attr_reader :tmp_files_to_cleanup

    class ZipFileUploadError < StandardError; end

    retry_on TranscriptionFileUpload::FileUploadError, wait: :exponentially_longer do |job, _exception|
      job.cleanup_tmp_files
      fail ZipFileUploadError
    end

    def perform(hearing_lookup_hashes)
      @tmp_files_to_cleanup = []
      ensure_current_user_is_set
      hearing_lookup_hashes.each do |hearing_lookup_hash|
        process_hearing(hearing_lookup_hash)
      end
      true
    end

    def cleanup_tmp_files
      @tmp_files_to_cleanup&.each { |path| File.delete(path) if File.exist?(path) }
      Rails.logger.info("Cleaned up the following files from tmp: #{@tmp_files_to_cleanup}")
    end

    private

    ALLOWED_HEARING_CLASSES = {
      "Hearing" => Hearing,
      "LegacyHearing" => LegacyHearing
    }.freeze

    TRANSCRIPTION_FILE_TYPES = %w[mp3 rtf].freeze

    def process_hearing(hearing_lookup_hash)
      hearing = fetch_hearing(hearing_lookup_hash)
      tmp_file_paths = fetch_transcription_files(hearing)
      zip_file_path = create_zip_file(tmp_file_paths, hearing)
      formatted_zip_path = rename_before_upload(zip_file_path)
      @tmp_files_to_cleanup += tmp_file_paths + [formatted_zip_path]
      create_and_upload_transcription_file(hearing, formatted_zip_path)
    end

    def fetch_hearing(hearing_lookup_hash)
      hearing_class = ALLOWED_HEARING_CLASSES[hearing_lookup_hash[:hearing_type]]
      hearing_class.find(hearing_lookup_hash[:hearing_id])
    end

    def fetch_transcription_files(hearing)
      hearing.transcription_files.where(file_type: TRANSCRIPTION_FILE_TYPES).map(&:fetch_file_from_s3!)
    end

    def create_zip_file(file_paths, hearing)
      zip_file_name = generate_zip_file_name(hearing)
      FileUtils.mkdir_p(File.dirname(zip_file_name))
      Zip::File.open(zip_file_name, create: true) do |zip_file|
        file_paths.each { |path| zip_file.add(File.basename(path), path) }
      end
      zip_file_name
    end

    def generate_zip_file_name(hearing)
      File.join(
        Rails.root, "tmp", "transcription_files", "zip", "#{hearing.docket_number}_#{hearing.id}_#{hearing.class}.zip"
      )
    end

    def rename_before_upload(zip_file_path)
      checksum = xor_checksum(zip_file_path)
      creation_date = format_creation_date(zip_file_path)
      new_path = zip_file_path.sub(".", "-#{checksum}-#{creation_date}.")
      File.rename(zip_file_path, new_path)
      new_path
    end

    def xor_checksum(file_path)
      checksum = File.open(file_path, "rb").each_byte.reduce(0, :^)
      checksum.to_s(16)
    end

    def format_creation_date(file_path)
      File.ctime(file_path).strftime("%Y%m%d")
    end

    def create_and_upload_transcription_file(hearing, file_path)
      TranscriptionFile.create!(
        file_name: File.basename(file_path),
        hearing_id: hearing.id,
        hearing_type: hearing.class.name,
        docket_number: hearing.docket_number,
        file_type: "zip",
        created_by_id: RequestStore[:current_user].id
      ).upload_to_s3!
    rescue ActiveRecord::RecordInvalid => error
      Rails.logger.error "Failed to create transcription file: #{error.message}"
    end
  end
end
