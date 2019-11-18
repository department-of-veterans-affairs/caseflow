# frozen_string_literal: true

class Message < ApplicationRecord
  belongs_to :user
  belongs_to :detail, polymorphic: true

  enum message_type: {
    job_note_added: "job_note_added",
    job_failing: "job_failing",
    failing_job_succeeded: "failing_job_succeeded",
    job_canceled: "job_canceled"
  }

  scope :read, -> { where.not(read_at: nil) }
  scope :unread, -> { where(read_at: nil) }
end
