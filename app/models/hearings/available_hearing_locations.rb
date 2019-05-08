# frozen_string_literal: true

class AvailableHearingLocations < ApplicationRecord
  belongs_to :veteran, foreign_key: :file_number, primary_key: :veteran_file_number
  belongs_to :appeal, polymorphic: true
end
