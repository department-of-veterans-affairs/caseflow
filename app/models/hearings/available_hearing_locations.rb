class AvailableHearingLocations < ApplicationRecord
  belongs_to :veteran, foreign_key: :file_number, primary_key: :veteran_file_number
end
