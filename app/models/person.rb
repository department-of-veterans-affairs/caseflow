class Person < ApplicationRecord
  has_many :advance_on_docket_grants
  validates :participant_id, presence: true
end