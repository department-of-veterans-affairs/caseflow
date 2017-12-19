require "datadog/statsd"

class DataDogService
  @statsd = Datadog::Statsd.new
  @host = `curl http://instance-data/latest/meta-data/instance-id --silent || echo "not-ec2"`.strip

  def self.increment_counter(metric_group:, metric_name:, app_name:, attrs: {})
    tags = get_tags(app_name, attrs)
    stat_name = get_stat_name(metric_group, metric_name)
    @statsd.increment(stat_name, tags: tags)
  end

  def self.emit_gauge(metric_group:, metric_name:, metric_value:, app_name:, attrs: {})
    tags = get_tags(app_name, attrs)
    stat_name = get_stat_name(metric_group, metric_name)
    @statsd.gauge(stat_name, metric_value, tags: tags)
  end

  private_class_method def self.get_stat_name(metric_group, metric_name)
    "dsva-appeals.#{metric_group}.#{metric_name}"
  end

  private_class_method def self.get_tags(app_name, attrs)
    extra_tags = attrs.reduce([]) do |tags, (key, val)|
      tags + ["#{key}:#{val}"]
    end
    [
      "app:#{app_name}",
      "env:#{Rails.env}",
      # I am not sure that dogstatsd lets us set the hostname.
      # https://github.com/DataDog/dogstatsd-ruby/issues/66
      "hostname:#{@host}"
    ] + extra_tags
  end
end
