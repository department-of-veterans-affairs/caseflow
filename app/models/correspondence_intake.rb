# frozen_string_literal: true

class CorrespondenceIntake < ApplicationRecord
  belongs_to :correspondence
  belongs_to :user

  validates :correspondence_id, presence: true
  validates :user_id, presence: true
end
