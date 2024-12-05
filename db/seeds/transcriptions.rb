module Seeds
  class Transcriptions < Base
    def seed!
      create_transcriptions
    end

    def create_transcriptions
      Transcription.find_or_create_by(
        created_by_id: User.system_user.id,
        hearing_type: 'Hearing',
        hearing_id: 7,
        transcription_status: 'unassigned',
        task_id: 1)
    end
  end
end
