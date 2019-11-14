# frozen_string_literal: true

# rr = RequestIssueReporter.new(start_date: 4.weeks.ago)
class RequestIssueReporter
  attr_reader :stats

  def initialize(start_date: Constants::DATES["AMA_ACTIVATION"].to_date, end_date: Time.zone.today)
    @start_date = start_date
    @end_date = end_date
    @stats = build
  end

  def as_csv
    CSV.generate do |csv|
      csv << %w[
        week_of
        rating
        nonrating
        unidentified
        unidentified_percent
      ]
      stats.each do |week, stat|
        total = stat[:rating] + stat[:nonrating] + stat[:unidentified]
        csv << [
          week.to_date,
          stat[:rating],
          stat[:nonrating],
          stat[:unidentified],
          ((total == 0) ? 0 : (stat[:unidentified].fdiv(total) * 100).round(2))
        ]
      end
    end
  end

  private

  attr_reader :start_date, :end_date

  def build
    stats = {}
    week_of = start_date.next_week # start the first Monday after the start_date
    while week_of < end_date
      stats[week_of] = summary_of_request_issues_for_week(week_of)
      week_of = week_of.next_week
    end
    stats
  end

  def summary_of_request_issues_for_week(week_of)
    start_week = week_of
    end_week = week_of.next_week
    {
      rating: rating_request_issues.where("created_at >= ? AND created_at < ?", start_week, end_week).count,
      nonrating: RequestIssue.nonrating.where("created_at >= ? AND created_at < ?", start_week, end_week).count,
      unidentified: RequestIssue.unidentified.where("created_at >= ? AND created_at < ?", start_week, end_week).count
    }
  end

  def rating_request_issues
    RequestIssue.where.not(
      contested_rating_issue_reference_id: nil
    ).or(RequestIssue.where.not(contested_rating_decision_reference_id: nil))
  end
end
