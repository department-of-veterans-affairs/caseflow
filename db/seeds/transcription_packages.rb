module Seeds
  class TranscriptionPackages < Base
    def seed!

      legacy_hearings = LegacyHearing.last(300)
      hearings = Hearing.last(300)

      contractors = TranscriptionContractor.all

      statuses = [
        "Successful Upload (BOX)",
        "Overdue",
        "Successful Upload (AWS)",
        "Failed Upload (BOX)",
        "Successful Retrieval (BOX)",
        "Failed Retrieval (BOX)"
      ]



      year = '2040'
      transcription_files_per_transcription = [1, 2]
      hearings_per_package = [1, 2, 3]

      transcription_file_index = 0
      hearing_index = 0

      (0..39).each do |package_index|
        task_number = 'BVA' + year + (package_index + 1).to_s.rjust(4, '0')
        contractor = contractors[package_index % contractors.length]
        status = statuses[package_index % statuses.length]
        user = User.where(css_id: "TRANSCRIPTION_USER").first
        hearings_count = hearings_per_package[package_index % hearings_per_package.length]

        # clean up so this can run more than once
        transcription_package = TranscriptionPackage.where(task_number: task_number).first
        if transcription_package
          transcription_package.transcription_package_legacy_hearings.delete_all
          transcription_package.transcription_package_hearings.delete_all
          transcription_package.delete
        end
        transcriptions = Transcription.where(task_number: task_number)
        if transcriptions
          transcriptions.each do |transcription|
            TranscriptionFile.where(transcription_id: transcription.id).delete_all
          end
          transcriptions.delete_all
        end

        transcription_package_hearings = []
        transcription_package_legacy_hearings = []

        (0..hearings_count).each do

          # create transcription which could have multiple transcription files
          transcription = Transcription.create!(task_number: task_number)

          # pick either a hearing or legacy hearing to add to the package
          if hearing_index % 2
            hearing = hearings[hearing_index]
            transcription_package_hearings << hearing
          else
            hearing = legacy_hearings[hearing_index]
            transcription_package_legacy_hearings << hearing
          end

          transcription_files_count =
            transcription_files_per_transcription[transcription_file_index % transcription_files_per_transcription.length]

          (0..transcription_files_count).each do |file_index|

            # create transcription file based on hearing
            TranscriptionFile.create!(
              file_name: "#{hearing.docket_number}_#{hearing.id}_Hearing" + file_index.to_s + ".rtf",
              hearing_id: hearing.id,
              hearing_type: hearing.class.name,
              docket_number: hearing.docket_number,
              file_type: "rtf",
              created_by_id: user.id,
              transcription_id: transcription.id
            )

            transcription_file_index += 1
          end

          hearing_index += 1
        end

        created_at = Time.parse('2024-09-01') + (package_index * 2).days
        expected_return_date = created_at + 14.days

        # create final transcription package with hearing associations
        TranscriptionPackage.create!(
          aws_link_zip: "vaec-appeals-caseflow-test/transcript_text/" + task_number + ".zip",
          aws_link_work_order: "vaec-appeals-caseflow-test/transcript_text/" + task_number + ".xls",
          contractor_id: contractor.id,
          created_by_id: user.id,
          created_at: created_at,
          returned_at: '',
          expected_return_date: expected_return_date,
          task_number: task_number,
          status: status,
          hearings: transcription_package_hearings,
          legacy_hearings: transcription_package_legacy_hearings
        )

      end

    end
  end
end
