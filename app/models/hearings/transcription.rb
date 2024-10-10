# frozen_string_literal: true

class Transcription < CaseflowRecord
  belongs_to :hearing, polymorphic: true
  belongs_to :transcription_contractor
  has_many :transcription_files
  belongs_to :transcription_package, foreign_key: :task_number, primary_key: :task_number
  before_create :sequence_task_id

  validates :hearing_type, inclusion: { in: %w[Hearing LegacyHearing] }
  validates :hearing, presence: true

  validate :hearing_must_exist

  scope :counts_for_this_week, lambda {
    where(sent_to_transcriber_date: Time.zone.today.beginning_of_week.yesterday..Time.zone.today)
      .group(:transcription_contractor_id)
      .count
  }

  scope :first_empty_transcription_file, lambda {
    where(transcription_status: "unassigned").order(:task_id).first
  }

  def self.unassign_by_task_number(task_number)
    where(task_number: task_number).update_all(transcription_status: "unassigned")
  end

  private

  def sequence_task_id
    self.task_id = Hearings::TranscriptionSequenceId.new(User.system_user.id, task_id)
      .before_insert_on_transcriptions(self)
  end

  def hearing_must_exist
    errors.add(:hearing, "must exist") if hearing.blank?
  end
end
