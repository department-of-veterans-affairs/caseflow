# frozen_string_literal: true

class Message < CaseflowRecord
  belongs_to :user
  belongs_to :detail, polymorphic: true

  enum message_type: {
    job_note_added: "job_note_added",
    job_failing: "job_failing",
    failing_job_succeeded: "failing_job_succeeded",
    job_cancelled: "job_cancelled"
  }

  scope :read, -> { where.not(read_at: nil) }
  scope :unread, -> { where(read_at: nil) }
  scope :created_after, ->(datetime) { where("created_at > :datetime", datetime: datetime) }
end

# (This section is updated by the annotate gem)
# == Schema Information
#
# Table name: messages
#
#  id           :bigint           not null, primary key
#  detail_type  :string           indexed => [detail_id]
#  message_type :string
#  read_at      :datetime
#  text         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null, indexed
#  detail_id    :integer          indexed => [detail_type]
#  user_id      :integer          not null
#
# Foreign Keys
#
#  fk_rails_273a25a7a6  (user_id => users.id)
#
