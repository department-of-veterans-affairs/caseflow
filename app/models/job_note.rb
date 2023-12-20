# frozen_string_literal: true

class JobNote < CaseflowRecord
  belongs_to :user
  belongs_to :job, polymorphic: true

  scope :newest_first, -> { order(created_at: :desc) }

  def serialize
    Intake::JobNoteSerializer.new(self).serializable_hash[:data][:attributes]
  end

  def path
    "#{job.path}#job-note-#{id}"
  end
end
