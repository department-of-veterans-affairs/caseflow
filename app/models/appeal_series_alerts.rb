class AppealSeriesAlerts
  include ActiveModel::Model

  attr_accessor :appeal_series

  delegate :latest_appeal, to: :appeal_series

  def all
    [
      form9_needed,
      scheduled_hearing,
      hearing_no_show,
      held_for_evidence,
      ramp,
      cavc_option
    ].compact
  end

  private

  def form9_needed
    if appeal_series.status == :pending_form9 && Time.zone.today <= latest_appeal.form9_due_date
      {
        type: :form9_needed,
        details: {
          due_date: latest_appeal.form9_due_date
        }
      }
    end
  end

  def scheduled_hearing
    if appeal_series.active? && !latest_appeal.scheduled_hearings.empty?
      hearing = latest_appeal.scheduled_hearings.sort_by(&:date).first
      {
        type: :scheduled_hearing,
        details: {
          date: hearing.date.to_date,
          type: hearing.type
        }
      }
    end
  end

  def hearing_no_show
    if appeal_series.active?
      recent_missed_hearing = latest_appeal.hearings.find do |hearing|
        hearing.no_show? && Time.zone.today <= hearing.no_show_excuse_letter_due_date
      end

      return unless recent_missed_hearing

      due_date = latest_appeal.hearings
                              .select(&:no_show?)
                              .map(&:no_show_excuse_letter_due_date)
                              .max

      {
        type: :hearing_no_show,
        details: {
          due_date: due_date
        }
      }
    end
  end

  def held_for_evidence
    if appeal_series.status == :on_docket
      hearing_with_pending_hold = latest_appeal.hearings.find do |hearing|
        hearing.held_open? && Time.zone.today <= hearing.hold_release_date
      end

      return unless hearing_with_pending_hold

      due_date = latest_appeal.hearings
                              .select(&:held_open?)
                              .map(&:hold_release_date)
                              .max

      {
        type: :held_for_evidence,
        details: {
          due_date: due_date
        }
      }
    end
  end

  def cavc_option
    cavc_due_date = appeal_series.appeals.map(&:cavc_due_date).compact.max

    return unless cavc_due_date && Time.zone.today <= cavc_due_date

    {
      type: :cavc_option,
      details: {
        due_date: cavc_due_date
      }
    }
  end

  def ramp
    if appeal_series.ramp_election && Time.zone.today <= appeal_series.ramp_election.due_date
      {
        type: appeal_series.eligible_for_ramp? ? :ramp_eligible : :ramp_ineligible,
        details: {
          due_date: appeal_series.ramp_election.due_date
        }
      }
    end
  end
end
