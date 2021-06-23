# frozen_string_literal: true

# Concern for MdrTask and MandateHoldTask to placed itself on hold for 90 days to wait for CAVC's mandate.
##

module CavcTimedHoldConcern
  extend ActiveSupport::Concern

  def update_timed_hold
    ActiveRecord::Base.transaction do
      children.open.where(type: :TimedHoldTask).last&.cancelled!
      create_timed_hold_task
    end
  end

  def create_timed_hold_task
    days_to_hold = days_until_90day_reminder
    if days_to_hold > 0
      TimedHoldTask.create_from_parent(
        self,
        days_on_hold: days_to_hold,
        instructions: default_instructions
      )
    end
  end

  private

  def days_until_90day_reminder
    decision_date = appeal.cavc_remand.decision_date
    end_date = decision_date + 90.days
    # convert to the number of days from today
    (end_date - Time.zone.today).to_i
  end
end
