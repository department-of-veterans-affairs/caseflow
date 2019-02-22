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
      decision_soon,
      blocked_by_vso,
      ramp,
      ama_opt_in_eligible,
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
      hearing = latest_appeal.scheduled_hearings.min_by(&:scheduled_for)
      {
        type: :scheduled_hearing,
        details: {
          date: hearing.scheduled_for.to_date,
          type: hearing.readable_request_type.downcase,
          location: hearing.request_type_location
        }
      }
    end
  end

  def hearing_no_show
    if appeal_series.active?
      most_recent_missed_hearing = latest_appeal.hearings.select do |hearing|
        hearing.no_show? && Time.zone.today <= hearing.no_show_excuse_letter_due_date
      end
        .max_by(&:scheduled_for)

      return unless most_recent_missed_hearing

      {
        type: :hearing_no_show,
        details: {
          date: most_recent_missed_hearing.scheduled_for.to_date,
          due_date: most_recent_missed_hearing.no_show_excuse_letter_due_date
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

  def decision_soon
    if appeal_series.status == :decision_in_progress || (appeal_series.status == :on_docket && appeal_series.at_front)
      {
        type: :decision_soon,
        details: {}
      }
    end
  end

  def blocked_by_vso
    if appeal_series.status == :at_vso && appeal_series.at_front
      {
        type: :blocked_by_vso,
        details: { vso_name: appeal_series.representative_name }
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
    if appeal_series.ramp_election.try(&:due_date) && Time.zone.today <= appeal_series.ramp_election.due_date
      {
        type: appeal_series.eligible_for_ramp? ? :ramp_eligible : :ramp_ineligible,
        details: {
          date: appeal_series.ramp_election.notice_date,
          due_date: appeal_series.ramp_election.due_date
        }
      }
    end
  end

  def ama_opt_in_eligible
    soc_opt_in_due_date = appeal_series.appeals.map(&:soc_opt_in_due_date).compact.max
    return unless soc_opt_in_due_date

    if FeatureToggle.enabled?(:api_appeal_status_v3) && appeal_series.active? && Time.zone.today <= soc_opt_in_due_date
      {
        type: :ama_opt_in_eligible,
        details: {
          due_date: soc_opt_in_due_date
        }
      }
    end
  end
end
