# frozen_string_literal: true

module Collectors::StatsCollector

  # Given metric_name_prefix and a hash like { "hearing.disposition" => Hearing.group(:disposition).count },
  # the result will be an array of metrics like:
  # [ { :metric => "#{metric_name_prefix}.hearing.disposition", :value => 300, "disposition" => "held" },
  #   { :metric => "#{metric_name_prefix}.hearing.disposition", :value => 100, "disposition" => "postponed" }
  # ]
  def flatten_stats(metric_name_prefix, stats_hash)
    [].tap do |stats|
      stats_hash.each do |metric_name, counts_hash|
        unless valid_metric_name?(metric_name)
          fail "Invalid metric name #{metric_name}; "\
            "see https://docs.datadoghq.com/developers/metrics/#naming-custom-metrics"
        end

        stats.concat add_tags_to_group_counts(metric_name_prefix, metric_name, counts_hash)
      end
    end
  end

  protected

  def add_tags_to_group_counts(prefix, metric_name, group_counts)
    tag_key = to_valid_tag(metric_name.split(".").last)
    group_counts.map do |key, count|
      { :metric => "#{prefix}.#{metric_name}", :value => count, tag_key => to_valid_tag(group_key_to_name(key)) }
    end
  end

  # See valid tag name rules at https://docs.datadoghq.com/tagging/#defining-tags
  def to_valid_tag(name)
    name.gsub(/[^a-zA-Z_\-\:\.\d\/]/, "__")
  end

  def valid_metric_name?(metric_name)
    # Actual limit is 200 but since the actual metric name in DataDog has
    # "dsva_appeals.stats_collector_job." prepended, let's just stick with a 150 character limit.
    return false if metric_name.length > 150

    return true if metric_name =~ /\A[a-zA-Z][a-zA-Z\d_\.]*\Z/

    false
  end

  def group_key_to_name(key)
    return "nil" unless key

    return key.map(&:parameterize).map(&:underscore).join(".") if key.instance_of?(Array)

    return key.parameterize.underscore if key.instance_of?(String)

    key.to_s.parameterize.underscore
  end
end
