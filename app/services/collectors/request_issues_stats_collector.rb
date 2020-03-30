# frozen_string_literal: true

# Collect stats for unidentified RequestIssues that have contentions,
# grouped by closed_status, benefit_type, decision_review_type, etc.
# The stats are typically used for monthly reporting.
# This collector is used by StatsCollectorJob.
class Collectors::RequestIssuesStatsCollector
  METRIC_NAME_PREFIX = "request_issues.unidentified_with_contention"

  # :reek:FeatureEnvy
  def collect_stats
    start_of_month = Time.zone.now.prev_month.beginning_of_month
    req_issues = unidentified_request_issues_with_contention(start_of_month, start_of_month.next_month)

    {}.tap do |stats|
      stats[METRIC_NAME_PREFIX] = req_issues.count

      req_issues.group(:closed_status).count.each do |status, count|
        stats["#{METRIC_NAME_PREFIX}.closed_status.#{status || 'nil'}"] = count
      end

      req_issues.group(:benefit_type).count.each do |ben_type, count|
        stats["#{METRIC_NAME_PREFIX}.benefit.#{ben_type}"] = count
      end

      dr_counts_by_type = req_issues.group(:decision_review_type).count
      dr_counts_by_type.each do |dr_type, count|
        stats["#{METRIC_NAME_PREFIX}.decision_review.#{dr_type}"] = count
      end

      # Could use `req_issues.group(:veteran_participant_id).count.count` but there's a count discrepancy
      stats["#{METRIC_NAME_PREFIX}.vet_count"] = req_issues.map(&:decision_review).map(&:veteran_file_number).uniq.count
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
