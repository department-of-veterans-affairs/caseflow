# frozen_string_literal: true

require "webvtt"
require "rtf"
require "csv"

# Workflow for converting VTT transcription files to RTF
class TranscriptionTransformer
  class FileConversionError < StandardError; end

  def initialize(vtt_path, hearing_info)
    @vtt_path = vtt_path
    @error_count = 0
    @hearing_info = hearing_info
    @length = 0
  end

  def call
    paths = [convert_to_rtf(@vtt_path)]
    csv_path = @vtt_path.gsub("vtt", "csv")
    if File.exist?(csv_path)
      paths.push(csv_path)
    elsif @error_count > 0
      paths.push(build_csv(csv_path, @error_count, @length, @hearing_info))
    end
    paths
  end

  private

  # Convert vtt file to rtf or csv if there is an error
  # Params: path - the file path of the vtt file
  # Returns the file path of the newly converted file
  def convert_to_rtf(path)
    rtf_path = path.gsub("vtt", "rtf")
    return rtf_path if File.exist?(rtf_path)

    begin
      converted_file = File.open(path, "r") { |io| io.read.encode("UTF-8", invalid: :replace, replace: "...") }
      File.open(path, "w") { |file| file.write(converted_file) }
      vtt = WebVTT.read(path)
      @length = vtt.actual_total_length
      doc = RTF::Document.new(RTF::Font.new(RTF::Font::ROMAN, "Times New Roman"))
      doc.footer = RTF::FooterNode.new(doc, RTF::FooterNode::UNIVERSAL)
      doc.style.left_margin = 1300
      doc.style.right_margin = 1300
      create_cover_page(doc)
      doc.page_break
      create_transcription_pages(vtt, doc)
      raw_doc = create_footer_and_spacing(doc)
      File.open(rtf_path, "w") { |file| file.write(raw_doc) }
      rtf_path
    rescue StandardError
      raise FileConversionError
    end
  end

  # Create cover page
  # Params: document - the document object
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
  # Params:
  #       transcript - the original vtt file
  #       document - the document object
  # Returns the document with the transcription pages
  def create_transcription_pages(transcript, document)
    styles = {}
    styles["PS_CODE"] = RTF::ParagraphStyle.new
    styles["CS_CODE"] = RTF::CharacterStyle.new
    styles["PS_CODE"].line_spacing = -1
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
  # Params: transcript - the original vtt file
  # Returns the compressed transcript
  def format_transcript(transcript)
    compressed_transcript = []
    prev_id = "<PLACEHOLDER> This is not anyones name."
    index = -1
    transcript.cues.each do |cue|
      identifier = cue.identifier&.strip&.scan(/[a-zA-Z]+/)&.join(" ") || ""
      name = (identifier == "") ? "Unknown" : identifier
      original_text = cue.text
      @error_count += original_text.scan("[...]").size
      prev_id = name
      compressed_transcript.push(identifier: name, text: original_text)
      index += 1
    end

    compressed_transcript
  end

  # create the footer
  # Params: document - the document object
  # returns the document with the footer
  def create_footer_and_spacing(document)
    document.footer << "Insert Veteran's Last Name, First Name, MI, Claim No"
    rtf_footer =
      "\\footer\\pard\\" + (" " * 47) + "\\chpgn" + (" " * 18) + "Veteran's Last, First, Claim No\\par"
    rtf_spacing = "sl120\\slmult1"
    raw_rtf = document.to_rtf.sub(document.footer.to_rtf, "{#{rtf_footer}}")
    raw_rtf.gsub("sl-1", rtf_spacing)
  end

  # streamlines adding line breaks
  # Params:
  #       row - the current row in the document
  #       count - amount of line breaks to add
  def insert_line_breaks(row, count)
    i = 0
    while i < count
      row.line_break
      i += 1
    end
  end

  # Builds csv which captures error and details of vtt file
  # Params: count - count of how many inaudibles were found
  #         length - total length of meeting
  #         hearing_info - object containing info about the hearing
  # Returns the created csv
  def build_csv(path, count, length, hearing_info)
    filename = path.split("/").last.sub(".csv", "")
    header = %w[length appeal_id hearing_date judge issues filename]
    length_string = "#{(length / 3600).floor}:#{(length / 60 % 60).floor}:#{(length % 60).floor}"
    CSV.open(path, "w") do |writer|
      writer << header
      writer << [length_string, hearing_info[:appeal_id], hearing_info[:date]&.strftime("%m/%d/%Y"),
                 hearing_info[:judge]&.upcase, "#{count} inaudible", filename]
    end
    path
  end

  # rubocop:disable Metrics/MethodLength
  # Generates the template info for the cover page
  # Params: row - the table row that the info will be occupying in the doc
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
