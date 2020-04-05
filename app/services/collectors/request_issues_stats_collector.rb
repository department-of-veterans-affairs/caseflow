# frozen_string_literal: true

# Collect stats for unidentified RequestIssues that have contentions,
# grouped by closed_status, benefit_type, decision_review_type, etc.
# The stats are typically used for monthly reporting.
# This collector is used by StatsCollectorJob.
class Collectors::RequestIssuesStatsCollector
  include Collectors::StatsCollector

  METRIC_NAME_PREFIX = "req_issues.w_contentions"

  # :reek:FeatureEnvy
  def collect_stats
    [].tap do |stats|
      group_count_hash = {
        "status" => request_issues_with_contention.group(:closed_status).count,
        "benefit" => request_issues_with_contention.group(:benefit_type).count,
        "decis_review" => request_issues_with_contention.group(:decision_review_type).count,

        "report" => monthly_report_hash
      }
      stats.concat flatten_stats(METRIC_NAME_PREFIX, group_count_hash)
    end
  end

  private

  def monthly_report_hash
    {
      "hlr_established" => HigherLevelReview
        .where("establishment_processed_at >= ?", start_date)
        .where("establishment_processed_at < ?", end_date).count,
      "sc_established" => SupplementalClaim
        .where("establishment_processed_at >= ?", start_date)
        .where("establishment_processed_at < ?", end_date).count,

      "030_end_products_established" => endproduct_establishment.where(source_type: "HigherLevelReview").count,
      "040_end_products_established" => endproduct_establishment.where(source_type: "SupplementalClaim").count,

      "created" => request_issues_with_contention.count,
      "edited" => edited_request_issues_with_contention.count,
      "unidentified_created" => request_issues_with_contention.where(is_unidentified: true).count,

      # Could use `req_issues.group(:veteran_participant_id).count.count` but there's a count discrepancy
      "vet_count" => request_issues_with_contention.map(&:decision_review).map(&:veteran_file_number).uniq.count
    }
  end

  def start_date
    @start_date ||= Time.zone.now.prev_month.beginning_of_month
  end

  def end_date
    @end_date ||= start_date.next_month
  end

  def endproduct_establishment
    EndProductEstablishment.where.not(reference_id: nil)
      .where("committed_at >= ?", start_date)
      .where("committed_at < ?", end_date)
  end

  def request_issues_with_contention
    @request_issues_with_contention ||= RequestIssue.where.not(contention_reference_id: nil)
      .where("created_at >= ?", start_date)
      .where("created_at < ?", end_date)
  end

  def edited_request_issues_with_contention
    @edited_request_issues_with_contention ||= RequestIssue.where.not(contention_reference_id: nil)
      .where.not(contention_updated_at: nil)
      .where("contention_updated_at >= ?", start_date)
      .where("contention_updated_at < ?", end_date)
  end
end
