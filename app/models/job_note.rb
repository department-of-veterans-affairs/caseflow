# frozen_string_literal: true

class JobNote < ApplicationRecord
  belongs_to :user
  belongs_to :job, polymorphic: true

  scope :newest_first, -> { order(created_at: :desc) }

  def ui_hash
    {
      id: id,
      user: user.css_id,
      created_at: created_at,
      note: note,
      sent_to_intake_user: send_to_intake_user
    }
  end

  def path
    "#{job.path}#job-note-#{id}"
  end
end
