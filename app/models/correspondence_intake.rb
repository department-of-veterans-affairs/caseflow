# frozen_string_literal: true

class CorrespondenceIntake < ApplicationRecord
  belongs_to :correspondence
  belongs_to :user

  validates :column, presence: :correspondence_id
  validates :column, presence: :user_id
end
