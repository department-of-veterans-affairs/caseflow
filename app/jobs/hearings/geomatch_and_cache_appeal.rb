# frozen_string_literal: true

class Hearings::GeomatchAndCacheAppeal < ApplicationJob
  queue_with_priority :high_priority
  application_attr :hearing_schedule

  def perform(appeal_id:)
    set_appeal(appeal_id)

    GeomatchService.new(appeal).geomatch
  end

  private

  attr_reader :appeal

  def set_appeal(appeal_id)
    appeal = LegacyAppeal.find(appeal_id)
  end
end
