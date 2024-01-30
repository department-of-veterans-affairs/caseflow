# frozen_string_literal: true

require "webvtt"

# Job for converting VTT transcription files to RTF
class Hearings::RTFConversionJob < CaseflowJob
  queue_with_priority :low_priority

  # Sub folder name
  S3_FOLDER_NAME = "vaec-appeals-caseflow"

  def initialize
    @logs = ["\nHearings::RTFConversion Log"]
    @folder_name = (Rails.deploy_env == :prod) ? S3_FOLDER_NAME : "#{S3_FOLDER_NAME}-#{Rails.deploy_env}"
    super
  end

  def perform
    vtt_file_paths = retreive_files_from_s3(files_waiting_for_conversion)
    convert_and_upload_files(["app/jobs/hearings/Transcript_IC_Webex.vtt"])
  end

  # Get transcription files waiting for file conversion
  # Return the vtt files that haven't been converted yet
  def files_waiting_for_conversion
    TranscriptionFile.where(date_converted: nil)
  end

  # Retrieve files from the s3 bucket
  # files - array of files needing to be converted
  # Return the list of newly made output paths
  def retreive_files_from_s3(files)
    paths = []
    files.pluck(:file_name).each do |file|
      s3_location = S3_FOLDER_NAME + "/" + file + ".vtt"
      S3Service.fetch_file(s3_location, vtt_folder)
      paths.push(vtt_folder)
    end

    paths
  end

  # Convert all the vtt files to rtf, upload to S3 and create records
  # paths - all the file paths of retrieved vtt files
  def convert_and_upload_files(paths)
    paths.each do |path|
      convert_to_rtf(path)
    end
  end

  # The temporary location of vtt files after fetching from S3
  # Return the location of the file
  def vtt_folder
    File.join(Rails.root, "tmp", "vtts", vtt_name)
  end

  # The temporary location of rtf files after fetching from S3
  # Return the location of the file
  def rtf_folder
    File.join("tmp", "vtts", rtf_name)
  end

  # The name of the vtt file after fetching
  # Return the name of the vtt file
  def vtt_name
    Time.zone.now.strftime("%m_%d_%Y_%H_%M_%S") + ".vtt"
  end

  # The name of the rtf file after fetching
  # Return the name of the rtf file
  def rtf_name
    Time.zone.now.strftime("%m_%d_%Y_%H_%M_%S") + ".rtf"
  end

  # Convert vtt file to rtf
  def convert_to_rtf(path)
    vtt = WebVTT.read(path)
    doc = RTF::Document.new(RTF::Font.new(RTF::Font::ROMAN, "Times New Roman"))
    transcript_info = create_header_page(vtt, doc)
    # byebug
    # styles = RTF::ParagraphStyle.new
    # vtt.cues.each do |cue|
    #   doc.paragraph(styles) do |style|
    #     style.paragraph << cue.identifier
    #     style.paragraph << cue.start.to_s + " --> " + cue.end.to_s
    #     style.paragraph << cue.text
    #   end
    # end
    # File.open('document.rtf', "w") { |file| file.write(doc.to_rtf) }
  end

  # Create header page
  def create_header_page(transcript, document)
    opening = transcript.cues[0]
    judge = opening.identifier.scan(/[a-zA-Z]+/).join(" ")
    veteran = /Veteran[^a]+([A-Z][a-z]+\s(?:[A-Z]\.\s)?[A-Z][A-Za-z]+)/.match(opening.text)
    date = /[Tt]oday.+\s([A-Z][a-z]+ \d+\w{2},\s\d{4})/.match(opening.text)
    representative = /represented\sby(\s|\sMs\.\s|\sMr\.\s|\sMrs\.\s)([A-Z][a-z]+\s(?:[A-Z]\.\s)?[A-Za-z]+)/
      .match(opening.text)
    border_width = 40
    document.table(2, 1, 8500) do |table|
      table[0].border_width = border_width
      table[1].border_width = border_width
      table[1][0].foreground(RTF::Colour.new(255, 255, 255))
      table[0].shading_colour = RTF::Colour.new(0, 0, 0)
      table[0][0] << "Department of Veterans Affairs"
    end
    File.open('document.rtf', "w") { |file| file.write(document.to_rtf) }

    # document.paragraph(styles) do |styles|
    #   style.paragraph << "Department of Veterans Affairs"
    # end
    {
      judge: judge,
      veteran: veteran && veteran[1] || "",
      date: date && date[1] || "",
      representative: representative && representative[2] || ""
    }
  end

  # Create a transcription file record
  def create_transcription_file(file_name, appeal_id, docket_number, date_converted, created_by_id, file_status)

  end

  # Upload file to S3 bucket
  def upload_to_s3

  end

  # Create an xls file for errors
  def create_xls_file

  end

end
