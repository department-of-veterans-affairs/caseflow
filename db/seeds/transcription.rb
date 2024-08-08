module Seeds
  class Transcription < Base

    def seed!
      Transcription.create(created_by_id: User.system_user.id, hearing_id: 7, transcription_status: 'unassigned', task_id: 987)
      Transcription.create(created_by_id: User.system_user.id, hearing_id: 7, transcription_status: 'unassigned', task_id: 10538)
    end
  end
end
