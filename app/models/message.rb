# frozen_string_literal: true

class Message < ApplicationRecord
  belongs_to :user

  scope :read, -> { where.not(read_at: nil) }
  scope :unread, -> { where(read_at: nil) }
end
