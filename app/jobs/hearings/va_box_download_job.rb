# frozen_string_literal: true

class Hearings::VaBoxDownloadJob < CaseflowJob
  include Shoryuken::Worker
  queue_as :low_priority

  S3_BUCKET = "vaec-appeals-caseflow"

  shoryuken_options retry_intervals: [3.seconds, 30.seconds, 5.minutes, 30.minutes, 2.hours, 5.hours]

  class BoxDownloadError < StandardError; end
  class BoxDownloadJobFileUploadError < StandardError; end

  def perform
    box_service = ExternalApi::VaBoxService.new

    files_info = [
      { type: "file", id: "1640091891785", name: "242551_1_LegacyHearing.pdf", created_at: "2024-09-05T06:12:53-07:00" },
      { type: "file", id: "1640098775769", name: "230903-1_1_Hearing.zip", created_at: "2024-09-05T06:12:51-07:00" },
      { type: "file", id: "1640089532504", name: "242551_1_LegacyHearing.zip", created_at: "2024-09-05T06:12:50-07:00" },
      { type: "file", id: "1640086914155", name: "242551_1_LegacyHearing.doc", created_at: "2024-09-05T06:12:49-07:00" },
      { type: "file", id: "1640093104372", name: "240903-1_1_Hearing.doc", created_at: "2024-09-05T06:12:47-07:00" },
      { type: "file", id: "1640086880469", name: "240903-1_1_Hearing.pdf", created_at: "2024-09-05T06:12:46-07:00" }
    ]

    files_info.collect do |current_file|
      @file_status = "Successful upload (AWS)"
      @file_name = current_file[:name]
      tmp_folder = select_folder(@file_name)
      begin
        box_service.download_file(current_file[:id], tmp_folder)
      rescue StandardError => error
        Rails.logger.error "Error to download the file #{@file_name} from Box: #{error.message}"
        cleanup_tmp_file
        raise BoxDownloadError
      end
      if @file_extension == "zip"
        unzip_file(tmp_folder, current_file)
      else
        upload_to_s3(tmp_folder)
        update_database(current_file)
      end
    end
    true
  end

  private

  def update_database(current_file)
    hearing_id = @file_name.split("_")[1]
    hearing_type = @file_name.split("_")[2].split(".")[0]
    docket_number = @file_name.split("_")[0]
    file_type = File.extname(@file_name).delete(".").to_s

    transcription_records = TranscriptionFile.where(
      hearing_id: hearing_id, hearing_type: hearing_type, file_type: file_type
    )

    if transcription_records.count > 0
      transcription_records.each do |tr|
        tr.update!(
          date_upload_aws: Time.zone.today,
          updated_at: Time.zone.today,
          date_returned_box: current_file[:created_at]
        )
      end
    else
      TranscriptionFile.create!(
        hearing_id: hearing_id,
        hearing_type: hearing_type,
        docket_number: docket_number,
        file_name: @file_name,
        file_type: file_type,
        file_status: @file_status,
        date_upload_aws: Time.zone.today,
        aws_link: "vaec-appeals-caseflow-test/transcript_text/#{@file_name}"
      )
    end
  rescue ActiveRecord::RecordInvalid => error
    Rails.logger.error "Failed to create transcription file: #{error.message}"
  end

  def select_folder(filename)
    @file_extension = File.extname(filename).delete(".").to_s
    current_path = Rails.root.join("tmp", "file_from_box", @file_extension.to_s, filename.to_s)
    FileUtils.mkdir_p(File.dirname(current_path)) unless Dir.exists?(@file_extension)
    current_path
  end

  def unzip_file(tmp_folder, current_file)
    Zip::File.open(tmp_folder) do |zip_file|
      list_files = []
      zip_file.each do |f|
        f_path = Rails.root.join("tmp", "file_from_box", @file_extension.to_s, f.name.to_s)
        FileUtils.mkdir_p(File.dirname(f_path))
        zip_file.extract(f, f_path) unless File.exist?(f_path)
        list_files << f_path unless File.directory?(f_path.to_s)
      end
      list_files.each do |my_file|
        upload_s3_modified_transcription_file(my_file.to_s, current_file)
      end
    end
  end

  def upload_to_s3(tmp_folder)
    begin
      S3Service.store_file(s3_location, tmp_folder, :filepath)
    rescue StandardError => error
      Rails.logger.error "Error to upload #{@file_name} to S3: #{error.message}"
      @file_status = "Failed upload (AWS)"
      raise BoxDownloadJobFileUploadError
    end
  end

  def s3_location
    folder_name = (Rails.deploy_env == :prod) ? S3_BUCKET : "#{S3_BUCKET}-#{Rails.deploy_env}"
    "#{folder_name}/transcript_text/#{@file_name}"
  end

  def upload_s3_modified_transcription_file(file_path, current_file)
    @file_name = File.basename(file_path)
    upload_to_s3(file_path)
    update_database(current_file)
  end
end
