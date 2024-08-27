# frozen_string_literal: true

class Transcription < CaseflowRecord
  belongs_to :hearing
  belongs_to :transcription_contractor
  has_many :transcription_files

  before_create :sequence_task_id

  scope :counts_for_this_week, lambda {
    where(sent_to_transcriber_date: Time.zone.today.beginning_of_week.yesterday..Time.zone.today)
      .group(:transcription_contractor_id)
      .count
  }

  scope :first_empty_transcription_file, lambda {
    where(transcription_status: "unassigned").order(:task_id).first
  }

  private

  def sequence_task_id
    self.task_id = Hearings::TranscriptionSequenceId.new(User.system_user.id, task_id)
      .before_insert_on_transcriptions(self)
  end
end
