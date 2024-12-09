# frozen_string_literal: true

class Hearings::ZipAndUploadTranscriptionPackageJob < CaseflowJob
  include Hearings::SendTranscriptionIssuesEmail
  queue_as :low_priority
  S3_BUCKET = "vaec-appeals-caseflow"
  class ZipTranscriptionPackageUploadError < StandardError; end

  # retry_on TranscriptionFileUpload::FileUploadError, wait: :exponentially_longer do |job, _exception|
  #   job.cleanup_tmp_files
  #   details_hash = { error: { type: "upload" }, provider: "S3" }
  #   error_details = job.build_error_details(exception, details_hash)
  #   job.send_transcription_issues_email(error_details)
  #   fail ZipTranscriptionPackageUploadError
  # end

  def perform(work_order)
    @work_order = work_order
    @all_paths = []

    ActiveRecord::Base.transaction do
      fetch_files
      transcription_package_tmp = create_master_file_zip
      upload_transcription_package_to_s3(transcription_package_tmp)
      save_transcription_package_in_database(transcription_package_tmp)
    end
  end

  private

  def fetch_files
    @work_order_tmp_path = fetch_file("xls", @work_order[:work_order_name])
    @bom_file_tmp_path = fetch_file("json", @work_order[:work_order_name].sub("BVA", "BOM"))
    @transcription_files_zip_tmp_paths = fetch_all_files("zip")
  end

  def fetch_file(extension, filename)
    path = Rails.root.join("tmp", "transcription_files", extension, "#{filename}.#{extension}")
    @all_paths << path
    path
  end

  def fetch_all_files(extension)
    Dir.glob(Rails.root.join("tmp", "transcription_files", extension, "*.#{extension}")).tap do |files|
      @all_paths.concat(files)
    end
  end

  def create_master_file_zip
    zip_master_file_path = generate_zip_master_file_name
    Zip::File.open(zip_master_file_path, create: true) do |zip_file|
      zip_file.add(File.basename(@work_order_tmp_path), @work_order_tmp_path)
      zip_file.add(File.basename(@bom_file_tmp_path), @bom_file_tmp_path)
      @transcription_files_zip_tmp_paths.each { |path| zip_file.add(File.basename(path), path) }
    end
    rename_before_upload(zip_master_file_path)
  end

  def generate_zip_master_file_name
    File.join(
      Rails.root, "tmp", "transcription_files", "zip", "master.zip"
    )
  end

  def rename_before_upload(zip_master_file_path)
    checksum = xor_checksum(zip_master_file_path)
    new_name = File.basename(@work_order_tmp_path).sub("BVA", "BVA#{checksum}").split(".")[0]
    new_path = zip_master_file_path.sub("master", new_name)
    File.rename(zip_master_file_path, new_path)
    @all_paths << new_path
    new_path
  end

  def xor_checksum(zip_master_file)
    checksum = File.open(zip_master_file, "rb").each_byte.reduce(0, :^)
    checksum.to_s(16)
  end

  def upload_transcription_package_to_s3(transcription_package_tmp)
    transcription_package_name = File.basename(transcription_package_tmp)
    begin
      S3Service.store_file(s3_location(transcription_package_tmp), transcription_package_tmp, :filepath)
      Rails.logger.info("File successfully uploaded to S3 location")
    rescue StandardError => error
      Rails.logger.error "Transcription Package Job failed to upload Transcription Package
      #{transcription_package_name} to S3: #{error.message}"
      raise TranscriptionFileUpload
    end
  end

  def s3_location(file_path)
    folder_name = Rails.env.production? ? S3_BUCKET : "#{S3_BUCKET}-#{Rails.env}"
    "#{folder_name}/transcript_text/#{File.basename(file_path)}"
  end

  def save_transcription_package_in_database(transcription_package_tmp)
    transcription_package = TranscriptionPackage.create!(
      aws_link_zip: s3_location(transcription_package_tmp),
      aws_link_work_order: s3_location(@work_order_tmp_path),
      created_by_id: RequestStore[:current_user].id,
      status: "Successful upload (AWS)",
      task_number: @work_order[:work_order_name],
      expected_return_date: @work_order[:return_date],
      contractor_id: ::TranscriptionContractor.find_by(name: @work_order[:contractor_name])&.id
    )
    @work_order[:hearings].each do |hearing|
      TranscriptionPackageHearing.create!(
        hearing_id: hearing[:hearing_id],
        hearing_type: hearing[:hearing_type],
        transcription_package_id: transcription_package.id
      )
    end
  rescue ActiveRecord::RecordInvalid => error
    Rails.logger.error "Failed to create transcription package: #{error.message}"
  end

  def cleanup_tmp_files
    @all_paths&.each { |path| File.delete(path) if File.exist?(path) }
    Rails.logger.info("Cleaned up the following files from tmp: #{@all_paths}")
  end
end
