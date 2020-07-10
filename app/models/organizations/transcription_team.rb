# frozen_string_literal: true

class TranscriptionTeam < Organization
  def self.singleton
    TranscriptionTeam.first || TranscriptionTeam.create(name: "Transcription", url: "transcription")
  end
end
