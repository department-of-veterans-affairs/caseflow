class TranscriptionContractor < ApplicationRecord
  validates :qat_name, presence: true
  validates :qat_directory, presence: true
end
