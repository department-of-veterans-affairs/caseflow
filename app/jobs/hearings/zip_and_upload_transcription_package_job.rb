# frozen_string_literal: true

class Hearings::ZipAndUploadTranscriptionPackageJob < CaseflowJob
  include Hearings::SendTranscriptionIssuesEmail
  queue_as :low_priority
  S3_BUCKET = "vaec-appeals-caseflow"
  class ZipTranscriptionPackageUploadError < StandardError; end

  retry_on TranscriptionFileUpload::FileUploadError, wait: :exponentially_longer do |job, _exception|
    job.cleanup_tmp_files
    details_hash = { error: { type: "upload" }, provider: "S3" }
    error_details = job.build_error_details(exception, details_hash)
    job.send_transcription_issues_email(error_details)
    fail ZipTranscriptionPackageUploadError
  end

  def initialize(*args)
    super(*args)
    @work_order_tmp_path = nil
    @transcription_files_zip_tmp_path = []
    @bom_file_tmp_path = nil
    @all_path = []
  end

  def perform(work_order)
    @work_order_tmp_path = fetch_work_order_file_tmp(work_order)
    fetch_all_transcription_files_zip_tmp
    @bom_file_tmp_path = fetch_bom_file_tmp(work_order)
    transcription_package_tmp = create_master_file_zip
    upload_transcription_package_to_s3(transcription_package_tmp)
    save_transcription_package_in_database(transcription_package_tmp, work_order)
    true
  end

  def cleanup_tmp_files
    @all_path&.each { |path| File.delete(path) if File.exist?(path) }
    Rails.logger.info("Cleaned up the following files from tmp: #{@all_path}")
  end

  private

  def fetch_work_order_file_tmp(work_order)
    current_path = File.open("tmp/transcription_files/xls/#{work_order[:work_order_name]}.xls")
    @all_path << current_path
    current_path
  end

  def fetch_all_transcription_files_zip_tmp
    Dir.each_child("tmp/transcription_files/zip") do |zip_files|
      @transcription_files_zip_tmp_path << File.open("tmp/transcription_files/zip/#{zip_files}")
      @all_path << File.open("tmp/transcription_files/zip/#{zip_files}")
    end
  end

  def fetch_bom_file_tmp(work_order)
    bom_name = work_order[:work_order_name].sub("BVA", "BOM")
    current_path = File.open("tmp/transcription_files/json/#{bom_name}.json")
    @all_path << current_path
    current_path
  end

  def create_master_file_zip
    zip_master_file_path = add_to_master
    rename_before_upload(zip_master_file_path)
  end

  def generate_zip_master_file_name
    File.join(
      Rails.root, "tmp", "transcription_files", "zip", "master.zip"
    )
  end

  def add_to_master
    tmp_master_zip_path = generate_zip_master_file_name
    Zip::File.open(tmp_master_zip_path, create: true) do |zip_file|
      zip_file.add(File.basename(@work_order_tmp_path), @work_order_tmp_path)
      zip_file.add(File.basename(@bom_file_tmp_path), @bom_file_tmp_path)
      @transcription_files_zip_tmp_path.each { |path| zip_file.add(File.basename(path), path) }
    end
    tmp_master_zip_path
  end

  def rename_before_upload(zip_master_file_path)
    checksum = xor_checksum(zip_master_file_path)
    new_name = File.basename(@work_order_tmp_path).sub("BVA", "BVA#{checksum}").split(".")[0]
    new_path = zip_master_file_path.sub("master", new_name)
    File.rename(zip_master_file_path, new_path)
    @all_path << new_path
    new_path
  end

  def xor_checksum(zip_master_file)
    checksum = File.open(zip_master_file, "rb").each_byte.reduce(0, :^)
    checksum.to_s(16)
  end

  def upload_transcription_package_to_s3(transcription_package_tmp)
    transcription_package_name = File.basename(transcription_package_tmp)
    begin
      S3Service.store_file(s3_location_master_file(transcription_package_tmp), transcription_package_tmp, :filepath)
      Rails.logger.info("File successfully uploaded to S3 location")
    rescue StandardError => error
      Rails.logger.error "Transcription Package Job failed to upload Transcription Package
      #{transcription_package_name} to S3: #{error.message}"
      raise TranscriptionFileUpload
    end
  end

  def s3_location_work_order
    file_name = File.basename(@work_order_tmp_path)
    folder_name = (Rails.deploy_env == :prod) ? S3_BUCKET : "#{S3_BUCKET}-#{Rails.deploy_env}"
    "#{folder_name}/transcript_text/#{file_name}"
  end

  def s3_location_master_file(transcription_package_tmp)
    file_name = File.basename(transcription_package_tmp)
    folder_name = (Rails.deploy_env == :prod) ? S3_BUCKET : "#{S3_BUCKET}-#{Rails.deploy_env}"
    "#{folder_name}/transcript_text/#{file_name}"
  end

  def save_transcription_package_in_database(transcription_package_tmp, work_order)
    ::TranscriptionPackage.create!(
      aws_link_zip: s3_location_master_file(transcription_package_tmp),
      aws_link_work_order: s3_location_work_order,
      created_by_id: RequestStore[:current_user].id,
      status: "Successful upload (AWS)",
      returned_at: nil,
      task_number: work_order[:work_order_name],
      contractor_id: ::TranscriptionContractor.find_by(name: work_order[:contractor_name])&.id
    )
  rescue ActiveRecord::RecordInvalid => error
    Rails.logger.error "Failed to create transcription file: #{error.message}"
  end
end
