class TranscriptionTask < GenericTask
  def available_actions(_user)
    [Constants.TASK_ACTIONS.RESCHEDULE_HEARING.to_h, Constants.TASK_ACTIONS.COMPLETE_TRANSCRIPTION.to_h]
  end
end
