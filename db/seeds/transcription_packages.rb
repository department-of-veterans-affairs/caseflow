module Seeds
  class TranscriptionPackages < Base
    def seed!

      #legacy_hearings = LegacyHearing.last(40)
      hearings = Hearing.last(300)

      contractors = TranscriptionContractor.all

      statuses = [
        "Successful upload (AWS)"
      ]

      year = '2040'
      item_counts = [2,5,10,1,3]

      hearing_index = 0
      (0..39).each do |index|
        task_number = 'BVA' + year + (index+1).to_s.rjust(4, '0')
        contractor = contractors[index % contractors.length]
        status = statuses[index % statuses.length]
        user = User.where(css_id: "TRANSCRIPTION_USER").first
        item_count = item_counts[index % item_counts.length]

        TranscriptionPackage.where(task_number: task_number).delete_all
        transcriptions = Transcription.where(task_number: task_number)
        if transcriptions
          transcriptions.each do |transcription|
            TranscriptionFile.where(transcription_id: transcription.id).delete_all
          end
          transcriptions.delete_all
        end

        (0..item_count).each do |count|
          hearing = hearings[hearing_index]
          hearing_index+=1
          transcription = Transcription.create!(task_number: task_number)
          TranscriptionFile.create!(
            file_name: "#{hearing.docket_number}_#{hearing.id}_Hearing.rtf",
            hearing_id: hearing.id,
            hearing_type: hearing.class.name,
            docket_number: hearing.docket_number,
            file_type: "rtf",
            created_by_id: user.id,
            transcription_id: transcription.id
          )
        end

        created_at = Time.parse('2024-09-01') + (index * 2).days
        expected_return_date = created_at + 14.days

        TranscriptionPackage.create!(
          aws_link_zip: "vaec-appeals-caseflow-test/transcript_text/" + task_number + ".zip",
          aws_link_work_order: "vaec-appeals-caseflow-test/transcript_text/" + task_number + ".xls",
          contractor_id: contractor.id,
          created_by_id: user.id,
          created_at: created_at,
          returned_at: '',
          expected_return_date: expected_return_date,
          task_number: task_number,
          status: status
        )
      end

    end
  end
end
