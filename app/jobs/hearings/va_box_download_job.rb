# frozen_string_literal: true

class VaBoxDownloadJob < CaseflowJob
  include Shoryuken::Worker
  queue_as :low_priority

  S3_BUCKET = "vaec-appeals-caseflow"

  shoryuken_options retry_intervals: [3.seconds, 30.seconds, 5.minutes, 30.minutes, 2.hours, 5.hours]

  class BoxDownloadError < StandardError; end

  files_info = [{
    id: "1616340906412" ,
    created_at: "2024-08-08T11:31:52-07:00",
    name: "test_folder_8.zip"
  },
  {
    id: "1616214697959" ,
    created_at: "2024-08-08T09:10:50-07:00",
    name: "test_folder_7.zip"
  },
  {
    id: "1614148391199" ,
    created_at: "2024-08-06T11:11:23-07:00",
    name: "test_folder_6.zip"
  },
  {
    id: "1610958779890" ,
    created_at: "2024-08-02T12:28:31-07:00",
    name: "test_folder_1.zip"
  },
]

  def perform(files_info)
    @file_extension = ""
    @file_name = ""

    box_service = ExternalApi::VaBoxService.new()

    files_info.collect do |current_file|
      @file_status = "Successful upload (AWS)"
      @file_name = current_file[:name]
      tmp_folder = select_folder(@file_name)
      box_service.download_file(current_file[:id], tmp_folder)
      upload_to_s3(tmp_folder)
      update_database(current_file)
    end
  end

  private

  def update_database(current_file)
    file ||= TranscriptionFile.find(current_file[:id])

    if file
      file.update!(
        date_upload_aws: Time.zone.today,
        date_returned_box: current_file[:created_at]
      )
    else
      TranscriptionFile.create!(
        # hearing_id: hearing.id,
        # hearing_type: "LegacyHearing",
        # docket_number: hearing.docket_number,
        file_name: current_file[:name],
        file_type: @file_extension,

        file_status: @file_status,
        date_upload_aws: Time.zone.today,
        aws_link: "vaec-appeals-caseflow-test/#{dir}/#{file_name}"
      )
    end

  end

  def select_folder(filename)
    @file_extension = File.extname(filename).delete('.').to_s
    return Rails.root.join("tmp", "file_from_box", "#{@file_extension}","#{filename}" )
  end

  def upload_to_s3(tmp_folder)
    begin
      binding.pry
      S3Service.store_file(s3_location, tmp_folder, :filepath)
    rescue StandardError => error
      Rails.logger.error "Error to upload #{@file_name} to S3: #{error.message}"
      @file_status = "Failed upload (AWS)"
      raise WorkOrderFileUploadError
    end
  end

  def s3_location
    folder_name = (Rails.deploy_env == :prod) ? S3_BUCKET : "#{S3_BUCKET}-#{Rails.deploy_env}"
    "#{folder_name}/transcript_text/#{@file_name}"
  end

end
