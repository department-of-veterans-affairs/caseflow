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

      legacy_hearings = LegacyHearing.last(40)
      hearings = Hearing.last(40)

      transcription_files.each do |file|
        (0..39).each do |index|

          if file[:hearingType] == 'Legacy'
            hearing = legacy_hearings[index]
          else
            hearing = hearings[index]
          end

          if hearing
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
end
