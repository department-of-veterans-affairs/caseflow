# frozen_string_literal: true

class TranscriptionPackageLegacyHearing < ApplicationRecord
  belongs_to :legacy_hearing
  belongs_to :transcription_package
end
