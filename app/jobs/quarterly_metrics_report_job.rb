# frozen_string_literal: true

###
# Quarterly stats sent to jobs slack channel. These are manually sent on to OIT.

class QuarterlyMetricsReportJob < RecurringMetricsReportJob
  def perform
    @period = "Quarterly"
    @start_date = Time.zone.today.prev_month.at_beginning_of_month - 2.months
    @end_date = Time.zone.today.prev_month.at_end_of_month.end_of_day

    run
  end

  private

  def additional_metrics
    hearings_show_rate = Metrics::HearingsShowRate.new(Metrics::DateRange.new(start_date, end_date))
    ep_creation_rate = Metrics::NonDenialDecisions.new(Metrics::DateRange.new(start_date, end_date))

    [
      "#{hearings_show_rate.name}: #{(hearings_show_rate.call * 100).round(2)}%",
      "#{ep_creation_rate.name}: #{(ep_creation_rate.call * 100).round(2)}%",
      "Mean time to recovery: See the 'Quarterly OIT Report' tab of the 'Caseflow Incident Stats' Google Sheet (https://docs.google.com/spreadsheets/d/1OAx_eRhwTaEM9aMx7eGg4KMR3Jgx5wYvsVBypHsZq5Q/edit#gid=593310513)"
    ]
  end
end
