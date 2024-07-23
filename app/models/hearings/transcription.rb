# frozen_string_literal: true

class Transcription < CaseflowRecord
  belongs_to :hearing
  belongs_to :transcription_contractor

  scope :count_for_this_week, lambda {
    where(sent_to_transcriber_date: Time.zone.today.beginning_of_week.yesterday..Time.zone.today)
      .group(:transcription_contractor_id)
      .count
  }
end
