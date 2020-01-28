# frozen_string_literal: true

# Reports the number of Request Issues by origin type week-over-week

class RequestIssueReporter
  include Reporter

  attr_reader :stats

  def initialize(start_date: Constants::DATES["AMA_ACTIVATION"].to_date, end_date: Time.zone.tomorrow)
    @start_date = start_date
    @end_date = end_date
    @stats = build
  end

  # rubocop:disable Metrics/MethodLength
  def as_csv
    CSV.generate do |csv|
      csv << %w[
        week_of
        rating_issue
        rating_decision
        nonrating
        decision_issue
        unidentified
        unidentified_percent
      ]
      stats.each do |week, stat|
        total = stat[:rating_issue] +
                stat[:rating_decision] +
                stat[:decision_issue] +
                stat[:nonrating] +
                stat[:unidentified]
        csv << [
          week.to_date,
          stat[:rating_issue],
          stat[:rating_decision],
          stat[:nonrating],
          stat[:decision_issue],
          stat[:unidentified],
          (total == 0) ? 0 : percent(stat[:unidentified], total)
        ]
      end
    end
  end
  # rubocop:enable Metrics/MethodLength

  private

  attr_reader :start_date, :end_date

  def build
    stats = {}
    week_of = start_date.monday? ? start_date : start_date.next_week # start the first Monday after the start_date
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
      rating_issue: RequestIssue.rating_issue.where("created_at >= ? AND created_at < ?", start_week, end_week).count,
      rating_decision: RequestIssue.rating_decision
        .where("created_at >= ? AND created_at < ?", start_week, end_week).count,
      nonrating: RequestIssue.nonrating.where("created_at >= ? AND created_at < ?", start_week, end_week).count,
      decision_issue: RequestIssue.decision_issue
        .where("created_at >= ? AND created_at < ?", start_week, end_week).count,
      unidentified: RequestIssue.unidentified.where("created_at >= ? AND created_at < ?", start_week, end_week).count
    }
  end
end
