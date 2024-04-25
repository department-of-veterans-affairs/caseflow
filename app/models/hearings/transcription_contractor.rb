class TranscriptionContractor < ApplicationRecord
  validates :name, presence: true
  validates :directory, presence: true
end
