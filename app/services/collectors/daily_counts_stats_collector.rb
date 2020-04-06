# frozen_string_literal: true

# Collect daily stats for basic objects. Each query should complete within 10 seconds.
# This collector is used by StatsCollectorJob.
class Collectors::DailyCountsStatsCollector
  TOTALS_METRIC_NAME_PREFIX = "daily_counts.totals"
  INCREMENTS_METRIC_NAME_PREFIX = "daily_counts.increments"

  def collect_stats
    {}.tap do |stats|
      stats.merge! flatten_stats total_counts_hash(TOTALS_METRIC_NAME_PREFIX)
      stats.merge! flatten_stats daily_counts(INCREMENTS_METRIC_NAME_PREFIX)
    end
  end

  private

  def flatten_stats(stats_hash)
    {}.tap do |stats|
      stats_hash.each do |key_namespace, counts_hash|
        stats.merge! prepend_namespace_to_keys(key_namespace, counts_hash)
      end
    end
  end

  def prepend_namespace_to_keys(namespace, hash)
    hash.transform_keys { |key| "#{namespace}.#{key_to_name(key)}" }
  end

  def key_to_name(key)
    return "nil" unless key

    return key.map(&:parameterize).map(&:underscore).join(".") if key.instance_of?(Array)

    return key.parameterize.underscore if key.instance_of?(String)

    key.to_s.parameterize.underscore
  end

  def total_counts_hash(prefix)
    {
      "#{prefix}.claimant.decision_review" => Claimant.group(:decision_review_type).count,
      # => {"HigherLevelReview"=>75769, "SupplementalClaim"=>336809, "Appeal"=>48793}
      "#{prefix}.claimant.payee_code" => Claimant.group(:payee_code).count,
      # => {nil=>430595, "13"=>45, "17"=>1, "11"=>669, "00"=>14258, "60"=>75, "29"=>1, "10"=>15599, "12"=>89, ...

      "#{prefix}.certification.office" => Certification.group(:certifying_office).count,
      # => {nil=>39579, "Nashville, TN"=>2657, "Little Rock, AR"=>1796, "Indianapolis, IN"=>2607, ...
      "#{prefix}.certification.rep" => Certification.group(:vacols_representative_type).count,
      # => {nil=>55738, "Service Organization"=>77601, "Agent"=>3246, "None"=>8588, "Attorney"=>36092, ...

      "#{prefix}.hearing" => Hearing.group(:disposition).count,
      # => {nil=>432, "postponed"=>577, "no_show"=>125, "held"=>1253, "cancelled"=>219}

      "#{prefix}.hearing_virtual" => VirtualHearing.group(:hearing_type).count,
      # => {"LegacyHearing"=>9}

      "#{prefix}.distribution" => Distribution.all.group(:status).count,
      # => {"completed"=>5090, "error"=>1431}

      "#{prefix}.case_review" => {
        "judge" => JudgeCaseReview.count,
        "attorney" => AttorneyCaseReview.count
      },

      "#{prefix}.decision_doc" => DecisionDocument.group(:appeal_type).count,
      # => {"Appeal"=>8047, "LegacyAppeal"=>63192}

      "#{prefix}.claim_establishment" => ClaimEstablishment.group(:decision_type).count,
      # => {nil=>40, "full_grant"=>46292, "partial_grant"=>29677, "remand"=>111624}

      "#{prefix}.req_issues" => RequestIssue.group(:decision_review_type).count,
      # => {nil=>78, "HigherLevelReview"=>172753, "Appeal"=>125898, "SupplementalClaim"=>717169}
      "#{prefix}.decision_issues" => DecisionIssue.group(:benefit_type, :disposition).count,
      # => {["fiduciary", "remanded"]=>2, ["pension", "dismissed_matter_of_law"]=>31, ["vha", "Granted"]=>70, ...

      "#{prefix}.dispatch" => Dispatch::Task.group(:type, :aasm_state).count
      # => {["EstablishClaim", "started"]=>5, ["EstablishClaim", "unprepared"]=>64, ...
    }
  end

  def daily_counts(prefix)
    {
      "#{prefix}.appeal" => query_yesterdays(Appeal).group(:docket_type).count,
      # => {"evidence_submission"=>52, "hearing"=>269, "direct_review"=>36}

      prefix => {
        "legacy_appeal" => query_yesterdays(LegacyAppeal).count,
        "appeal_series" => query_yesterdays(AppealSeries).count,
        "hearing" => query_yesterdays(Hearing).count,
        "legacy_hearing" => query_yesterdays(LegacyHearing).count
      },

      "#{prefix}.appeal.status" => count_groups(query_yesterdays(Appeal)) { |record| record.status.status },
      # => {:not_distributed=>349, :distributed_to_judge=>4, :cancelled=>2, :assigned_to_attorney=>2}

      "#{prefix}.appeal_series.num_of_appeals" =>
          count_groups(query_yesterdays(AppealSeries)) { |record| record.appeals.count },
      # => {1=>555, 2=>56, 4=>12, 5=>3, 3=>20, 6=>1, 7=>2}

      "#{prefix}.distribution" => query_yesterdays(Distribution).group(:status).count
      # => {"completed"=>13, "error"=>3}
    }
  end

  def yesterday
    @yesterday ||= Time.now.utc.to_date.yesterday
  end

  def query_yesterdays(record_type, field = :created_at)
    record_type.where("#{field} >= ?", yesterday).where("#{field} < ?", yesterday.next_day)
  end

  def count_groups(array, &block)
    array.group_by(&block).map { |key, items| [key, items.count] }.to_h
  end
end
