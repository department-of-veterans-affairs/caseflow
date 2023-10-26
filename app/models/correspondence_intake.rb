# frozen_string_literal: true

class CorrespondenceIntake < ApplicationRecord
  belongs_to :correspondence
  belongs_to :user

  validates_presence_of :correspondence_id
  validates_presence_of :user_id
end
