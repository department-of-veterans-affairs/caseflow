# frozen_string_literal: true

###
# Monthly stats sent to jobs slack channel. These are manually sent on to OIT.

class MonthlyMetricsReportJob < RecurringMetricsReportJob
  def perform
    @period = "Monthly"
    @start_date = Time.zone.today.prev_month.at_beginning_of_month
    @end_date = Time.zone.today.prev_month.at_end_of_month.end_of_day

    run
  end
end
