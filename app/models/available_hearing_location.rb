class AvailableHearingLocation < ApplicationRecord
  belongs_to :veteran, foreign_key: :veteran_file_number, primary_key: :file_number
end