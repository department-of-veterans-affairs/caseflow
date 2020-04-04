# frozen_string_literal: true

# Collect stats for unidentified RequestIssues that have contentions,
# grouped by closed_status, benefit_type, decision_review_type, etc.
# The stats are typically used for monthly reporting.
# This collector is used by StatsCollectorJob.
class Collectors::RequestIssuesStatsCollector
  include Collectors::StatsCollector

  METRIC_NAME_PREFIX = "request_issues.unidentified"

  # :reek:FeatureEnvy
  def collect_stats
    start_of_month = Time.zone.now.prev_month.beginning_of_month
    req_issues = unidentified_request_issues_with_contention(start_of_month, start_of_month.next_month)

    [].tap do |stats|
      stats << { metric: METRIC_NAME_PREFIX, value: req_issues.count }

      # Could use `req_issues.group(:veteran_participant_id).count.count` but there's a count discrepancy
      stats << { metric: "#{METRIC_NAME_PREFIX}.vet_count",
                 value: req_issues.map(&:decision_review).map(&:veteran_file_number).uniq.count }

      group_count_hash = {
        "status" => req_issues.group(:closed_status).count,
        "benefit" => req_issues.group(:benefit_type).count,
        "decision_review" => req_issues.group(:decision_review_type).count
      }
      stats.concat flatten_stats(METRIC_NAME_PREFIX, group_count_hash)
    end
  end

  private

  def unidentified_request_issues_with_contention(start_date, end_date)
    RequestIssue.where.not(contention_reference_id: nil)
      .where(is_unidentified: true)
      .where("created_at >= ?", start_date)
      .where("created_at < ?", end_date)
  end
end
