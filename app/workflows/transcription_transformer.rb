# frozen_string_literal: true

require "webvtt"
require "rtf"

# Workflow for converting VTT transcription files to RTF
class TranscriptionTransformer
  def initialize(vtt_path)
    @vtt_path = vtt_path
    @rtf_path = vtt_path.gsub("vtt", "rtf")
  end

  def call
    return @rtf_path if File.exist?(@rtf_path)

    convert_to_rtf(@vtt_path)
  end

  private

  # Convert vtt file to rtf or csv if there is an error
  # path - the file path of the vtt file
  # Returns the file path of the newly converted file
  def convert_to_rtf(path)
    begin
      vtt = WebVTT.read(path)
      doc = RTF::Document.new(RTF::Font.new(RTF::Font::ROMAN, "Times New Roman"))
      doc.footer = RTF::FooterNode.new(doc, RTF::FooterNode::UNIVERSAL)
      doc.style.left_margin = 1300
      doc.style.right_margin = 1300
      create_cover_page(doc)
      doc.page_break
      create_transcription_pages(vtt, doc)
      doc = create_footer(doc)
      File.open(@rtf_path, "w") { |file| file.write(doc) }
      @rtf_path
    rescue StandardError
      raise FileConversionError
    end
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
  # transcript - the original vtt file
  # Returns the compressed transcript
  def format_transcript(transcript)
    compressed_transcript = []
    prev_id = "<PLACEHOLDER> This is not anyones name."
    index = -1
    transcript.cues.each do |cue|
      identifier = cue.identifier.strip.scan(/[a-zA-Z]+/).join(" ")
      name = (identifier == "") ? "Unknown" : identifier
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
      "\\footer\\pard\\" + (" " * 47) + "\\chpgn" + (" " * 18) + "Veteran's Last, First, Claim No\\par"
    document.to_rtf.sub!(document.footer.to_rtf, "{#{rtf_footer}}")
  end

  # streamlines adding line breaks
  #     row - the current row in the document
  #     count - amount of line breaks to add
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
