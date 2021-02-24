# frozen_string_literal: true

##
# Shared methods of Hearing and LegacyHearing models
##
module HearingConcern
  extend ActiveSupport::Concern

  class_methods do
    def joins_with_cached_appeals_clause
      "left join #{CachedAppeal.table_name} "\
      "on #{CachedAppeal.table_name}.appeal_id = #{self.table_name}.appeal_id "\
      "and #{CachedAppeal.table_name}.appeal_type = '#{appeal_or_legacy_appeal.name}'"
    end

    def appeal_or_legacy_appeal
      self.class.is_a?(LegacyHearing) ? LegacyAppeal : Appeal
    end
  end

  # NOTE: for LegacyHearing, this makes a call to VACOLS
  def postponed?
    disposition == Constants.HEARING_DISPOSITION_TYPES.postponed
  end

  # NOTE: for LegacyHearing, this makes a call to VACOLS
  def cancelled?
    disposition == Constants.HEARING_DISPOSITION_TYPES.cancelled
  end

  # NOTE: for LegacyHearing, this makes a call to VACOLS
  def no_show?
    disposition == Constants.HEARING_DISPOSITION_TYPES.no_show
  end

  # NOTE: for LegacyHearing, this makes a call to VACOLS
  def held?
    disposition == Constants.HEARING_DISPOSITION_TYPES.held
  end

  # NOTE: for LegacyHearing, this makes a call to VACOLS
  def scheduled_in_error?
    disposition == Constants.HEARING_DISPOSITION_TYPES.scheduled_in_error
  end

  def postponed_or_cancelled_or_scheduled_in_error?
    postponed? || cancelled? || scheduled_in_error?
  end

  def open_hearing_disposition_task_id
    hearing_task = appeal.tasks.open.where(type: HearingTask.name).find { |task| task.hearing&.id == id }
    hearing_task
      &.children
      &.open
      &.find_by(type: [AssignHearingDispositionTask.name, ChangeHearingDispositionTask.name])
      &.id
  end
end
