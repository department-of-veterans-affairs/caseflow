# db/seeds/transcription_files.rb

module Seeds
  class TranscriptionFiles < Base

    def seed!
      transcription_files = [
        {
          fileStatus: Constants.TRANSCRIPTION_FILE_STATUSES.upload.success,
          hearingType: 'LegacyHearing',
          fileType: 'vtt',
          fileName: 'transcript.vtt'
        },
        {
          fileStatus: Constants.TRANSCRIPTION_FILE_STATUSES.conversion.success,
          hearingType: 'Hearing',
          fileType: 'rtf',
          fileName: 'transcript.rtf'
        },
        {
          fileStatus: 'conversion_success',
          hearingType: 'Hearing',
          fileType: 'csv',
          fileName: 'transcript.csv'
        },
      ]

      legacy_hearings = LegacyHearing.last(40)
      hearings = Hearing.last(40)

      year = '2041'
      task_index = 0

      transcription_files.each do |file|
        (0..39).each do |index|

          if file[:hearingType] == 'LegacyHearing'
            hearing = legacy_hearings[index]
          else
            hearing = hearings[index]
          end

          if hearing
            task_index += 1
            task_number = 'BVA' + year + (task_index).to_s.rjust(4, '0')

            TranscriptionPackage.where(task_number: task_number).delete_all
            transcriptions = Transcription.where(task_number: task_number)
            if transcriptions
              transcriptions.each do |transcription|
                TranscriptionFile.where(transcription_id: transcription.id).delete_all
              end
              transcriptions.delete_all
            end

            transcription = Transcription.create!(
              task_number: task_number,
              hearing_type: file[:hearingType],
              hearing_id: hearing.id
            )

            # Debugging information
            puts "Creating TranscriptionFile with hearing: #{hearing.inspect}, file: #{file.inspect}"

            TranscriptionFile.find_or_create_by(
              hearing: hearing,
              file_name: file[:fileName],
              file_status: file[:fileStatus],
              file_type: file[:fileType],
              docket_number: hearing.docket_number,
              aws_link: "aws-link/#{hearing.docket_number}_#{hearing.id}_Hearing.vtt",
              transcription_id: transcription.id
            )
          else
            # Debugging information
            puts "No hearing found for file: #{file.inspect}, index: #{index}"
          end
        end
      end
    end
  end
end
