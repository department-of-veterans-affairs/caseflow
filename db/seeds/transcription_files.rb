module Seeds
  class TranscriptionFiles < Base

    def seed!
      transcription_files = [
        {
          fileStatus: Constants.TRANSCRIPTION_FILE_STATUSES.upload.success,
          hearingType: 'Legacy',
          fileType: 'vtt',
          fileName: 'transcript.vtt'
        },
        {
          fileStatus: Constants.TRANSCRIPTION_FILE_STATUSES.upload.success,
          hearingType: 'AMA',
          fileType: 'rtf',
          fileName: 'transcript.rtf'
        },
        {
          fileStatus: Constants.TRANSCRIPTION_FILE_STATUSES.conversion.success,
          hearingType: 'AMA',
          fileType: 'csv',
          fileName: 'transcript.csv'
        },
      ]

      legacy_hearings = LegacyHearing.last(20)
      hearings = Hearing.last(20)

      transcription_files.each do |file|
        (0..19).each do |index|

          if file[:hearingType] == 'Legacy'
            hearing = legacy_hearings[index]
          else
            hearing = hearings[index]
          end

          TranscriptionFile.find_or_create_by(
            hearing: hearing,
            file_name: file[:fileName],
            file_status: file[:fileStatus],
            file_type: file[:fileType],
            docket_number: hearing.docket_number,
            aws_link: "aws-link/#{hearing.docket_number}_#{hearing.id}_Hearing.vtt",
          )
        end
      end
    end
  end
end

# transcription_files2 = [{
#   docketNumber: '240325-1197',
#   caseDetails: 'John Smith (1000001)',
#   type: 'Original',
#   hearingDate: '5/10/2024',
#   hearingType: 'AMA',
#   status: 'Unassigned'
# },

# t.string "aws_link", comment: "Link to be used by HMB to download original or transformed file"
# t.bigint "created_by_id", comment: "The user who created the transcription record"
# t.datetime "date_converted", comment: "Timestamp when file was converted from vtt to rtf"
# t.datetime "date_receipt_webex", comment: "Timestamp when file was added to webex"
# t.datetime "date_upload_aws", comment: "Timestamp when file was loaded to AWS"
# t.datetime "date_upload_box", comment: "Timestamp when file was added to box"

# t.string "docket_number", null: false, comment: "Docket number of associated hearing"
# t.string "file_name", null: false, comment: "File name, with extension, of the transcription file migrated by caseflow"
# t.string "file_status", comment: "Status of the file, could be one of nil, 'Successful retrieval (Webex), Failed retrieval (Webex), Sucessful conversion, Failed conversion, Successful upload (AWS), Failed upload (AWS)'"
# t.string "file_type", null: false, comment: "One of mp4, vtt, mp3, rtf, pdf, xls"
# t.bigint "hearing_id", null: false, comment: "ID of the hearing associated with this record"
# t.string "hearing_type", null: false, comment: "Type of hearing associated with this record"

# t.datetime "created_at", null: false
# t.datetime "updated_at", null: false
# t.bigint "updated_by_id", comment: "The user who most recently updated the transcription file"

# t.index ["aws_link"], name: "index_transcription_files_on_aws_link"
# t.index ["docket_number"], name: "index_transcription_files_on_docket_number"
# t.index ["file_name", "docket_number", "hearing_id", "hearing_type"], name: "idx_transcription_files_on_file_name_and_docket_num_and_hearing", unique: true
# t.index ["file_type"], name: "index_transcription_files_on_file_type"
# t.index ["hearing_id", "hearing_type", "docket_number"], name: "index_transcription_files_on_docket_number_and_hearing"
# t.index ["hearing_id", "hearing_type"], name: "index_transcription_files_on_hearing_id_and_hearing_type"
