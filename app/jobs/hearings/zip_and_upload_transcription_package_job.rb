# frozen_string_literal: true

class Hearings::ZipAndUploadTranscriptionPackageJob < CaseflowJob

  queue_as :low_priority
  # attr_reader :tmp_files_to_cleanup

  class ZipTranscriptionPackageUploadError < StandardError; end

  retry_on TranscriptionFileUpload::FileUploadError, wait: :exponentially_longer do |job, _exception|
    # job.cleanup_tmp_files
    fail ZipTranscriptionPackageUploadError
  end


  def perform(work_order)
    work_order_tmp = fetch_work_order_file_tmp(work_order)
    transcription_files_zip_tmp = fetch_all_transcription_files_zip_tmp()
    bom_file_tmp = fetch_bom_file_tmp(work_order)
    transcription_package_tmp = create_master_file_zip(work_order_tmp, transcription_files_zip_tmp, bom_file_tmp)
    # Save this file in the DB?? create a new record yes
    # upload_to_s3!(transcription_package)
    true
  end

  private

  def fetch_work_order_file_tmp(work_order)
    File.open("tmp/transcription_files/xls/#{work_order[:work_order_name]}.xls")
  end

  def fetch_all_transcription_files_zip_tmp()
    all_zips_files = []
    Dir.each_child("tmp/transcription_files/zip") do |zip_files|
      all_zips_files << File.open("tmp/transcription_files/zip/#{zip_files}")
    end
    all_zips_files
  end

  def fetch_bom_file_tmp(work_order)
    bom_name = work_order[:work_order_name].sub("BVA", "BOM")
    File.open("tmp/transcription_files/json/#{bom_name}.json")
  end

  def create_master_file_zip(work_order_file, transcription_files_zip_tmp, bom_file_file)
    zip_master_file_path = add_to_master(work_order_file, transcription_files_zip_tmp, bom_file_file)
    formatted_zip_master_path = rename_before_upload(zip_master_file_path, work_order_file)
  end

  def generate_zip_master_file_name()
    File.join(
      Rails.root, "tmp", "transcription_files", "zip", "master.zip"
    )
  end

  def add_to_master(work_order_file, transcription_files_zip_tmp, bom_file_file)
    tmp_master_zip_path = generate_zip_master_file_name()
    Zip::File.open(tmp_master_zip_path, create: true) do |zip_file|
      zip_file.add(File.basename(work_order_file), work_order_file)
      zip_file.add(File.basename(bom_file_file), bom_file_file)
      transcription_files_zip_tmp.each { |path| zip_file.add(File.basename(path), path) }
    end
    tmp_master_zip_path
  end

  def rename_before_upload(zip_master_file_path, work_order_file)
    checksum = xor_checksum(zip_master_file_path)
    # creation_date = format_creation_date(zip_master_file)
    new_name = File.basename(work_order_file).sub("BVA", "BVA#{checksum}").split(".")[0]
    new_path = zip_master_file_path.sub("master", new_name)
    File.rename(zip_master_file_path, new_path)
    new_path
  end

  def xor_checksum(zip_master_file)
    checksum = File.open(zip_master_file, "rb").each_byte.reduce(0, :^)
    checksum.to_s(16)
  end

  def format_creation_date(zip_master_file)
    File.ctime(zip_master_file).strftime("%Y%m%d")
  end


end
