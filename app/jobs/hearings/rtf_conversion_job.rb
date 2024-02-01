# frozen_string_literal: true

require "webvtt"
require "rtf"

# Job for converting VTT transcription files to RTF
class Hearings::RTFConversionJob < CaseflowJob
  queue_with_priority :low_priority

  # Sub folder name
  S3_SUB_BUCKET = "vaec-appeals-caseflow"

  def initialize
    @logs = ["\nHearings::RTFConversion Log"]
    @folder = (Rails.deploy_env == :prod) ? S3_SUB_BUCKET : "#{S3_SUB_BUCKET}-#{Rails.deploy_env}"
    @upload_folder = @folder + "/transcript_text"
    super
  end

  def perform
    vtt_file_paths = retreive_files_from_s3(files_waiting_for_conversion)
    # vtt_file_paths = ["tmp/transcription_files/vtt/Transcript_IC_Webex.vtt"]
    convert_and_upload_files(vtt_file_paths)
    clean_up_tmp_folders
  end

  # Get transcription files waiting for file conversion
  # Returns the vtt files that haven't been converted yet
  def files_waiting_for_conversion
    TranscriptionFile.where(date_converted: nil).where.not(aws_link: [nil, ""])
  end

  # Retrieve files from the s3 bucket
  # files - array of files needing to be converted
  # Returns the list of newly made output paths
  def retreive_files_from_s3(files)
    paths = []
    files.pluck(:aws_link).each do |link|
      file_name = vtt_folder + "/" + vtt_name
      S3Service.fetch_file(link, file_name)
      paths.push(file_name)
    end

    paths
  end

  # Convert all the vtt files to rtf, upload to S3 and create records
  # paths - all the file paths of retrieved vtt files
  # Returns - the aws links the files were uploaded to
  def convert_and_upload_files(paths)
    aws_links = []
    paths.each do |path|
      rtf_path = convert_to_rtf(path)
      link = upload_to_s3(rtf_path)
      aws_links.push(link)
    end

    aws_links
  end

  # The temporary location of vtt files after fetching from S3
  # Returns the location of the file
  def vtt_folder
    File.join(Rails.root, "tmp", "transcription_files", "vtt")
  end

  # The temporary location of rtf files after fetching from S3
  # Returns the location of the file
  def rtf_folder
    File.join("tmp", "transcription_files", "rtf")
  end

  # The name of the vtt file after fetching
  # Returns the name of the vtt file
  def vtt_name
    Time.zone.now.strftime("%m_%d_%Y_%H_%M_%S_%L") + ".vtt"
  end

  # The name of the rtf file after fetching
  # Returns the name of the rtf file
  def rtf_name
    Time.zone.now.strftime("%m_%d_%Y_%H_%M_%S_%L") + ".rtf"
  end

  # Convert vtt file to rtf
  # path - the file path of the vtt file
  # Returns the file path of the newly converted file
  def convert_to_rtf(path)
    vtt = WebVTT.read(path)
    doc = RTF::Document.new(RTF::Font.new(RTF::Font::ROMAN, "Times New Roman"))
    doc.footer = RTF::FooterNode.new(doc, RTF::FooterNode::UNIVERSAL)
    doc.style.left_margin = 1300
    doc.style.right_margin = 1300
    create_cover_page(doc)
    doc.page_break
    create_transcription_pages(vtt, doc)
    doc = create_footer(doc)
    save_location = rtf_folder + "/" + rtf_name
    File.open(save_location, "w") { |file| file.write(doc) }
    save_location
  end

  # Create cover page
  # document - the document object
  # Returns the document with the cover page
  def create_cover_page(document)
    border_width = 40
    document.table(2, 1, 9200) do |table|
      table.cell_margin = 30
      header_row = table[0]
      header_row.border_width = border_width
      header_row.shading_colour = RTF::Colour.new(0, 0, 0)
      table[1].border_width = border_width
      header_row[0] << " Department of Veterans Affairs"
      generate_cover_info(table[1][0])
    end
  end

  # Create the text pages on the file
  #     transcript - the original vtt file
  #     document - the document object
  # Returns the document with the transcription pages
  def create_transcription_pages(transcript, document)
    styles = {}
    styles["PS_CODE"] = RTF::ParagraphStyle.new
    styles["CS_CODE"] = RTF::CharacterStyle.new
    styles["PS_CODE"].line_spacing = false
    styles["CS_CODE"].underline = true
    format_transcript(transcript).each do |cue|
      document.paragraph(styles["PS_CODE"]) do |n1|
        n1.apply(styles["CS_CODE"]) do |n2|
          n2 << cue[:identifier].upcase
        end
        n1.paragraph << ": #{cue[:text]}"
        n1.paragraph
      end
    end
  end

  # Format the transcript by consolidating speakers who talk multiple times in a row
  # transcript - the original vtt file
  # Returns the compressed transcript
  def format_transcript(transcript)
    compressed_transcript = []
    prev_id = "<PLACEHOLDER> This is not anyones name"
    index = -1
    transcript.cues.each do |cue|
      name = cue.identifier.scan(/[a-zA-Z]+/).join(" ")
      if name.match?(/#{prev_id}/)
        compressed_transcript[index][:text] += " " + cue.text
      elsif cue.text.strip != ""
        prev_id = name
        cue.identifier = name
        compressed_transcript.push(identifier: name, text: cue.text)
        index += 1
      end
    end

    compressed_transcript
  end

  # create the footer
  # document - the document object
  # returns the document with the footer
  def create_footer(document)
    document.footer << "Insert Veteran's Last Name, First Name, MI, Claim No"
    rtf_footer =
      "\\footer\\pard\\" + (" " * 47) + "\\chpgn" + (" " * 13) + "Veteran's Last, First, MI, Claim No\\par"
    document.to_rtf.sub!(document.footer.to_rtf, "{#{rtf_footer}}")
  end

  # Create a transcription file record
  def create_transcription_file(file_name, appeal_id, docket_number, date_converted, created_by_id, file_status)

  end

  # Upload file to S3 bucket
  # path - the file path of the rtf file
  # Returns the aws link
  def upload_to_s3(path)
    upload_location = @upload_folder + "/" + path.sub(rtf_folder + "/", "")
    S3Service.store_file(upload_location, path, :filepath)

    upload_location
  end

  # Create an xls file for errors
  def create_xls_file

  end

  # remove all vtt and rtfs
  def clean_up_tmp_folders
    FileUtils.rm_rf("#{vtt_folder}/.", secure: true)
    FileUtils.rm_rf("#{rtf_folder}/.", secure: true)

    nil
  end

  def insert_line_breaks(row, count)
    i = 0
    while i < count
      row.line_break
      i += 1
    end
  end

  # rubocop:disable Metrics/MethodLength
  # Generates the template info for the cover page
  # row - the table row that the info will be occupying in the doc
  # return the modified cover doc
  def generate_cover_info(row)
    insert_line_breaks(row, 1)
    row << "                                TRANSCRIPT OF HEARING"
    insert_line_breaks(row, 2)
    row << "                                           BEFORE"
    insert_line_breaks(row, 2)
    row << "                             BOARD OF VETERANS' APPEALS"
    insert_line_breaks(row, 2)
    row << "                                 WASHINGTON, D.C. 20420"
    insert_line_breaks(row, 4)
    row << "                            Video Conference at Insert City, State"
    insert_line_breaks(row, 4)
    row << "  IN THE APPEAL OF           :       Insert Veterans Last Name, First Name, MI"
    insert_line_breaks(row, 1)
    row << "                                           Insert Veteran's Claim No"
    insert_line_breaks(row, 5)
    row << "  DATE                          :       Insert Date"
    insert_line_breaks(row, 5)
    row << "  REPRESENTED BY           :       Insert Name of Representative"
    insert_line_breaks(row, 1)
    row << "                                          Insert Representative's Organization"
    insert_line_breaks(row, 5)
    row << "  MEMBER OF BOARD           :    Insert Veterans Law Judge's name, Judge"
    insert_line_breaks(row, 5)
    row << "  WITNESSES                   :       Insert Full Name of witness, Appellant"
    insert_line_breaks(row, 1)
    row << "                                            Insert Full Name of other witnesses, Witness"
    insert_line_breaks(row, 5)
  end
  # rubocop:enable Metrics/MethodLength
end
