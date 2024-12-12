# frozen_string_literal: true

class Hearings::VaBoxDownloadJob < CaseflowJob
  include Hearings::SendTranscriptionIssuesEmail

  queue_as :low_priority
  S3_BUCKET = "vaec-appeals-caseflow"

  class VaBoxDownloadJobError < StandardError; end
  class VaBoxDownloadBoxError < StandardError; end
  class VaBoxDownloadUnzipError < StandardError; end
  class VaBoxDownloadHearingError < StandardError; end
  class VaBoxDownloadTranscriptionError < StandardError; end
  class VaBoxDownloadTranscriptionPackageError < StandardError; end
  class VaBoxDownloadHearingHeldError < StandardError; end
  class VaBoxDownloadS3UploadError < StandardError; end

  def perform(files_info)
    @files = []
    download_files_from_box(files_info)
    handle_zip_files
    confirm_hearing_or_package
    upload_files_to_s3
    create_or_update_transcription_files
    cleanup_tmp_files
  end

  private

  def raise_error(message, error, send_email, fail_on_error)
    cleanup_tmp_files
    Rails.logger.error message

    job_summary = message + "\n\nFiles in batch: \n\n"
    @files.each do |file|
      job_summary += file[:name] + "\n"
    end
    send_transcription_issues_email(job_summary) if send_email
    fail error if fail_on_error
  end

  def download_files_from_box(files)
    box_service = ExternalApi::VaBoxService.new

    files.collect do |file|
      begin
        tmp_file_path = tmp_file_path(file[:name])
        box_service.download_file(file[:id], tmp_file_path)
        if File.file?(tmp_file_path)
          @files << {
            name: file[:name],
            created_at: file[:created_at],
            path: tmp_file_path.to_s,
            type: extract_file_type(file[:name])
          }
        end
      rescue StandardError
        raise_error("Failed to download file #{file[:name]} from box", VaBoxDownloadBoxError, false, true)
      end
    end
  end

  def handle_zip_files
    zip_files(@files).each do |file|
      unzip_file(file).each do |f|
        @files << f
      end
    end
  end

  def confirm_hearing_or_package
    non_zip(@files).each do |file|
      if file[:type] == "xls"
        confirm_package(file)
      else
        confirm_hearing(file)
      end
    end
  end

  def confirm_package(file)
    file[:task_number] = file[:name].gsub(/[_.]/, " ").split(" ").select { |e| e.include? "BVA" }

    package = find_package(file)

    if package
      file[:package_id] = package.id
    else
      raise_error(
        "Missing transcription package for #{file[:name]}", VaBoxDownloadTranscriptionPackageError, true, true
      )
    end
  end

  def confirm_hearing(file)
    file[:hearing_id] = file[:name].split("_")[1].to_i
    file[:hearing_type] = file[:name].split("_")[2].split(".")[0]
    file[:docket_number] = file[:name].split("_")[0]

    hearing = find_hearing(file)

    if hearing
      if hearing.held?
        transcription = find_transcription(file)
        if transcription
          file[:transcription_id] = transcription.id
        else
          raise_error("Missing transcription for #{file[:name]}", VaBoxDownloadTranscriptionError, true, true)
        end
      else
        raise_error(
          "Hearing (docket ##{file[:docket_number]}) not held for
          #{file[:name]}", VaBoxDownloadHearingHeldError, true, true
        )
      end
    else
      raise_error("Missing hearing for #{file[:name]}", VaBoxDownloadHearingError, true, true)
    end
  end

  def upload_files_to_s3
    non_zip(@files).each do |file|
      begin
        file[:aws_link] = s3_location(file[:name], file[:type])
        S3Service.store_file(file[:aws_link], file[:path], :filepath)
        file[:status] = "Successful upload (AWS)"
      rescue StandardError
        file[:status] = "Failed upload (AWS)"
        raise_error("Failed to uplaod file #{file[:name]} to S3", VaBoxDownloadS3UploadError, false, false)
      end
    end
  end

  def create_or_update_transcription_files
    non_zip(@files).each do |file|
      transcription_file = find_transcription_file(file)
      if transcription_file
        update_transcription_file(transcription_file, file)
      else
        create_transcription_file(file)
      end
    end
  end

  def find_package(file)
    TranscriptionPackage.where(
      task_number: file[:task_number]
    ).first
  end

  def find_hearing(file)
    if file[:hearing_type] == "Hearing"
      Hearing.where(id: file[:hearing_id]).first
    else
      LegacyHearing.where(id: file[:hearing_id]).first
    end
  end

  def find_transcription(file)
    Transcription.where(
      hearing_id: file[:hearing_id],
      hearing_type: file[:hearing_type]
    ).first
  end

  def find_transcription_file(file)
    TranscriptionFile.where(
      hearing_id: file[:hearing_id],
      hearing_type: file[:hearing_type],
      file_type: file[:type]
    ).first
  end

  def create_transcription_file(file)
    TranscriptionFile.create!(
      hearing_id: file[:hearing_id],
      hearing_type: file[:hearing_type],
      docket_number: file[:docket_number],
      file_name: file[:name],
      file_type: file[:type],
      file_status: file[:status],
      transcription_id: file[:transcription_id],
      date_upload_aws: Time.zone.now,
      aws_link: file[:aws_link],
      date_returned_box: file[:created_at]
    )
  end

  def update_transcription_file(transcription_file, file)
    transcription_file.update!(
      date_upload_aws: Time.zone.now,
      updated_at: Time.zone.now,
      date_returned_box: file[:created_at],
      file_status: file[:status],
      aws_link: file[:aws_link]
    )
  end

  def extract_file_type(file_name)
    File.extname(file_name).delete(".").to_s
  end

  def cleanup_tmp_files
    @files&.each { |file| File.delete(file[:path]) if File.exist?(file[:path]) }
  end

  def unzip_file(file)
    files = []
    begin
      Zip::File.open(file[:path]) do |zip_file|
        zip_file.each do |f|
          file_type = extract_file_type(f.to_s)
          f_path = Rails.root.join("tmp", "file_from_box", file_type, f.name.to_s)
          FileUtils.mkdir_p(File.dirname(f_path))
          zip_file.extract(f, f_path) unless File.exist?(f_path)
          next if File.directory?(f_path.to_s)

          files << { name: f.name.to_s, created_at: file[:created_at], path: f_path.to_s, type: file_type }
        end
      end

      files
    rescue StandardError => error
      raise_error("Error unzipping file #{file[:name]}: #{error.message}", VaBoxDownloadUnzipError, true, true)
    end
  end

  def non_zip(files)
    files.find_all { |file| file[:type] != "zip" }
  end

  def zip_files(files)
    files.find_all { |file| file[:type] == "zip" }
  end

  def tmp_file_path(file_name)
    file_type = extract_file_type(file_name)
    current_path = Rails.root.join("tmp", "file_from_box", file_type.to_s, file_name.to_s)
    FileUtils.mkdir_p(File.dirname(current_path)) unless Dir.exist?(file_type)
    current_path
  end

  def s3_location(file_name, file_type)
    transcript_text_path = (file_type == "pdf") ? "transcript_pdf" : "transcript_text"
    folder_name = (Rails.deploy_env == :prod) ? S3_BUCKET : "#{S3_BUCKET}-#{Rails.deploy_env}"
    "#{folder_name}/#{transcript_text_path}/#{file_name}"
  end
end
