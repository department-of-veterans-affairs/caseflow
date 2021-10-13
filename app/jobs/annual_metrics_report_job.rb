# frozen_string_literal: true

###
# Annual stats sent to jobs slack channel. These are manually sent on to OIT.

class AnnualMetricsReportJob < RecurringMetricsReportJob
  def perform
    @period = "Annual"
    @start_date = Time.zone.today.prev_month.at_beginning_of_month - 11.months
    @end_date = Time.zone.today.prev_month.at_end_of_month.end_of_day

    run
  end

  private

  def additional_metrics
    reader_adoption_rate = Metrics::ReaderAdoptionRate.new(Metrics::DateRange.new(start_date, end_date))

    ["#{reader_adoption_rate.name}: #{(reader_adoption_rate.call * 100).round(2)}%"]
  end
end
