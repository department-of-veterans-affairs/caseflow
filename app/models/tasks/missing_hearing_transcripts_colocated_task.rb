# frozen_string_literal: true

class MissingHearingTranscriptsColocatedTask < ColocatedTask
  def self.label
    Constants.CO_LOCATED_ADMIN_ACTIONS.missing_hearing_transcripts
  end
end
