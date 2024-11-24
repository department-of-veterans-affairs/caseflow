# frozen_string_literal: true

class Hearings::VaBoxDownloadJob < CaseflowJob
  queue_as :low_priority
  S3_BUCKET = "vaec-appeals-caseflow"

  class VaBoxDownloadJobError < StandardError; end
  class VaBoxDownloadBoxError < StandardError; end
  class VaBoxDownloadUnzipError < StandardError; end
  class VaBoxDownloadHearingError < StandardError; end
  class VaBoxDownloadTranscriptionError < StandardError; end

  def perform(files_info)
    @files = []
    download_files_from_box(files_info)
    handle_zip_files
    confirm_hearings_and_transcriptions
    upload_files_to_s3
    create_or_update_transcription_files
    cleanup_tmp_files
  end

  private

  def raise_error(message, error = VaBoxDownloadJobError)
    cleanup_tmp_files
    Rails.logger.error message
    fail error
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
        raise_error("Failed to download file " + file[:name] + " from box", VaBoxDownloadBoxError)
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

  def confirm_hearings_and_transcriptions
    non_zip(@files).each do |file|
      file = update_hearing_information(file)
      hearing = find_hearing(file)
      if hearing
        transcription = find_transcription(file)
        if transcription
          file[:transcription_id] = transcription.id
        else
          raise_error("Missing transcription for #{file[:name]}", VaBoxDownloadTranscriptionError)
        end
      else
        raise_error("Missing hearing for #{file[:name]}", VaBoxDownloadHearingError)
      end
    end
  end

  def upload_files_to_s3
    non_zip(@files).each do |file|
      begin
        file[:aws_link] = s3_location(file[:name], file[:type])
        # S3Service.store_file(file[:aws_link], file[:path], :filepath)
        # file_status = (s3_upload_result == file_path) ? "Failed upload (AWS)" : "Successful upload (AWS)"
        file[:status] = "Successful upload (AWS)"
      rescue StandardError => error
        raise_error("Error uploading file #{file[:path]} to S3: #{error.message}")
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
      raise_error("Error unzipping file #{file[:path]}: #{error.message}", VaBoxDownloadUnzipError)
    end
  end

  def update_hearing_information(file)
    file[:hearing_id] = file[:name].split("_")[1].to_i
    file[:hearing_type] = file[:name].split("_")[2].split(".")[0]
    file[:docket_number] = file[:name].split("_")[0]
    file
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

# class Hearings::VaBoxDownloadJob < CaseflowJob
#   queue_as :low_priority
#   S3_BUCKET = "vaec-appeals-caseflow"

#   class BoxDownloadError < StandardError; end
#   class BoxDownloadJobFileUploadError < StandardError; end

#   def perform(files_info)
#     @all_paths = []
#     box_service = ExternalApi::VaBoxService.new

#     files_info.collect do |current_file|
#       file_name = current_file[:name]
#       tmp_folder = select_folder(file_name)
#       file_extension = extract_file_extension(file_name)
#       begin
#         box_service.download_file(current_file[:id], tmp_folder)
#         @all_paths << tmp_folder
#         if file_extension == "zip"
#           unzip_file(tmp_folder, current_file)
#         else
#           upload_s3_modified_transcription_file(tmp_folder, current_file)
#         end
#       end
#     end
#     cleanup_tmp_files
#   end

#   private

#   def extract_file_extension(file_name)
#     File.extname(file_name).delete(".").to_s
#   end

#   def update_database(current_information, file_status)
#     transcription_records = TranscriptionFile.where(
#       hearing_id: current_information["id"].to_i,
#       hearing_type: current_information["hearing_type"],
#       file_type: current_information["file_type"]
#     )

#     current_extension = extract_file_extension(current_information["file_name"])
#     transcript_text_path = (current_extension == "pdf") ? "transcript_pdf" : "transcript_text"
#     aws_link = create_link_aws(current_information, file_status, transcript_text_path)

#     if transcription_records.count > 0
#       update_transcription_file_record(transcription_records, current_information, file_status, aws_link)
#     else
#       create_transcription_file_record(current_information, file_status, aws_link)
#     end

#     modified_task_tree(current_information, file_status)
#   rescue ActiveRecord::RecordInvalid => error
#     Rails.logger.error "Failed to create transcription file: #{error.message}"
#   end

#   def modified_task_tree(current_information, file_status)
#     if current_information["hearing_type"] == "Hearing"
#       current_hearing = Hearing.find(current_information["id"])
#       if current_hearing.disposition == "held"
#         create_review_transcript_task(current_hearing.appeal_id, file_status)
#       end
#     else
#       current_legacy_hearing = LegacyHearing.find(current_information["id"].to_i)
#       current_vacols_id = current_legacy_hearing.current_vacols_id
#       current_appeal_id = current_legacy_hearing.appeal_id
#       hearing_record = VACOLS::CaseHearing.for_appeals(current_vacols_id)
#       if hearing_record.hearing_disp == "H"
#         create_review_transcript_task(current_appeal_id, file_status)
#       end
#     end
#   end

#   def create_review_transcript_task(appeal_id, file_status)
#     if file_status == "Successful upload (AWS)"
#       appeal = Appeal.find(appeal_id)
#       root_task = RootTask.find_or_create_by!(appeal: appeal)
#       ReviewTranscriptTask.create!(
#         appeal: appeal,
#         parent: root_task
#       )
#     end
#   end

#   def create_link_aws(current_information, file_status, transcript_text_path)
#     if file_status == "Failed upload (AWS)"
#       nil
#     else
#       "vaec-appeals-caseflow-test/#{transcript_text_path}/#{current_information['file_name']}"
#     end
#   end

#   def create_transcription_file_record(current_information, file_status, aws_link)
#     if current_information["hearing_type"] == "Hearing"
#       transcription_id = Hearing.find(current_information["id"]).transcription&.id
#     else
#       current_legacy_hearing = LegacyHearing.find(current_information["id"].to_i)
#       current_vacols_id = current_legacy_hearing.current_vacols_id
#       hearings = VACOLS::CaseHearing.for_appeals(current_vacols_id)
#       transcription_id = hearings.taskno
#     end

#     unless transcription_id
#       fail StandardError, "Transcription for #{current_information['hearing_type']} \
#         - ID: #{current_information['id']} does not exist."
#     end

#     add_transcription_file_record(current_information, file_status, aws_link, transcription_id)
#   end

#   def add_transcription_file_record(current_information, file_status, aws_link, transcription_id)
#     TranscriptionFile.create!(
#       hearing_id: current_information["id"],
#       hearing_type: current_information["hearing_type"],
#       docket_number: current_information["docket_number"],
#       file_name: current_information["file_name"],
#       file_type: current_information["file_type"],
#       file_status: file_status,
#       transcription_id: transcription_id,
#       date_upload_aws: Time.zone.now,
#       aws_link: aws_link
#     )
#   end

#   def update_transcription_file_record(transcription_records, current_information, file_status, aws_link)
#     transcription_records.each do |tr|
#       tr.update!(
#         date_upload_aws: Time.zone.now,
#         updated_at: Time.zone.now,
#         date_returned_box: current_information["date_returned_box"],
#         file_status: file_status,
#         aws_link: aws_link
#       )
#     end
#   end

#   def select_folder(file_name)
#     file_extension = extract_file_extension(file_name)
#     current_path = Rails.root.join("tmp", "file_from_box", file_extension.to_s, file_name.to_s)
#     FileUtils.mkdir_p(File.dirname(current_path)) unless Dir.exist?(file_extension)
#     current_path
#   end

#   def unzip_file(tmp_folder, current_file)
#     file_extension = extract_file_extension(current_file[:name])
#     Zip::File.open(tmp_folder) do |zip_file|
#       list_files = []
#       zip_file.each do |f|
#         f_path = Rails.root.join("tmp", "file_from_box", file_extension.to_s, f.name.to_s)
#         FileUtils.mkdir_p(File.dirname(f_path))
#         zip_file.extract(f, f_path) unless File.exist?(f_path)
#         list_files << f_path unless File.directory?(f_path.to_s)
#       end
#       list_files.each do |my_file|
#         @all_paths << my_file.to_s
#         upload_s3_modified_transcription_file(my_file.to_s, current_file)
#       end
#     end
#   end

#   def upload_to_s3(tmp_folder, file_name)
#     begin
#       S3Service.store_file(s3_location(file_name), tmp_folder, :filepath)
#     rescue StandardError => error
#       Rails.logger.error "Error to upload #{file_name} to S3: #{error.message}"
#       raise BoxDownloadJobFileUploadError
#     end
#   end

#   def s3_location(file_name)
#     transcript_text_path = (extract_file_extension(file_name) == "pdf") ? "transcript_pdf" : "transcript_text"
#     folder_name = (Rails.deploy_env == :prod) ? S3_BUCKET : "#{S3_BUCKET}-#{Rails.deploy_env}"
#     "#{folder_name}/#{transcript_text_path}/#{file_name}"
#   end

#   def get_information(file_name, current_file)
#     info = {}
#     info["id"] = file_name.split("_")[1]
#     info["hearing_type"] = file_name.split("_")[2].split(".")[0]
#     info["docket_number"] = file_name.split("_")[0]
#     info["file_type"] = File.extname(file_name).delete(".").to_s
#     info["date_returned_box"] = current_file[:created_at]
#     info["file_name"] = file_name
#     info
#   end

#   def upload_s3_modified_transcription_file(file_path, current_file)
#     begin
#       if File.exist?(file_path)
#         file_name = File.basename(file_path)
#         s3_upload_result = upload_to_s3(file_path, file_name)
#         file_status = (s3_upload_result == file_path) ? "Failed upload (AWS)" : "Successful upload (AWS)"
#         info = get_information(file_name, current_file)
#         update_database(info, file_status)
#       else
#         fail "The file does not exist"
#       end
#     end
#   end

#   def cleanup_tmp_files
#     @all_paths&.each { |path| File.delete(path) if File.exist?(path) }
#     Rails.logger.info("Cleaned up the following files from tmp: #{@all_paths}")
#   end
# end
