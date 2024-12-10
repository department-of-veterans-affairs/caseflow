# frozen_string_literal: true

class TranscriptionPackageHearing < ApplicationRecord
  belongs_to :hearingable, polymorphic: true
  belongs_to :transcription_package
end
