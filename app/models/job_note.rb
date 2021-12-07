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

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: job_notes
#
#  id                  :bigint           not null, primary key
#  job_type            :string           not null, indexed => [job_id]
#  note                :text             not null
#  send_to_intake_user :boolean          default(FALSE)
#  created_at          :datetime         not null
#  updated_at          :datetime         not null, indexed
#  job_id              :bigint           not null, indexed => [job_type]
#  user_id             :bigint           not null, indexed
#
# Foreign Keys
#
#  fk_rails_03158cd475  (user_id => users.id)
#
