class Person < ApplicationRecord
  validates :participant_id, presence: true
end