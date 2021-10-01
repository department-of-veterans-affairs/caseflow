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
end
