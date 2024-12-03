# frozen_string_literal: true

class DeleteMetricsJob < CaseflowJob
  queue_with_priority :low_priority
  BATCH_SIZE = 1_000

  def initialize(options = {})
    @options = {}

    query_options(options)
  end

  def perform
    return unless options_included?

    metric_ids = metric_ids

    destroy_in_batches(metric_ids) unless metric_ids.blank?
  end

  def perform_dry_run
    return unless options_included?

    count = metric_ids.size

    "Dry Run: #{count} records would be deleted."
  end

  private

  def query_options(options)
    validate_metric_type(options[:metric_type])
    validate_metric_product(options[:metric_product])
    validate_metric_message(options[:metric_message])
    validate_date_range(options[:months])
  end

  def options_included?
    @options.any? { |_option_name, option_value| !option_value.nil? }
  end

  def validate_metric_type(metric_type)
    if Metric::METRIC_TYPES.value?(metric_type)
      @options[:metric_type]
    end
  end

  def validate_metric_product(metric_product)
    if Metric::PRODUCT_TYPES.value?(metric_product)
      @options[:metric_product] = metric_product
    end
  end

  def validate_date_range(months)
    return unless months.to_i.is_a?(Integer) && months.to_i > 0

    @options[:months] = months.to_i.months.ago
  end

  def validate_metric_message(metric_message)
    return unless metric_message.is_a?(String)

    @options[:metric_message] = metric_message
  end

  def metric_ids
    query_options = []
    @options.each do |option_name, option_value|
      case option_name
      when :metric_type
        query_options << "metric_type = \'#{option_value}\'"
      when :months
        query_options << "created_at < \'#{option_value}\'"
      when :metric_product
        query_options << "metric_product = \'#{option_value}\'"
      when :metric_message
        query_options << "metric_message ILIKE  \'%#{option_value}%\'"
      end
    end

    Metric.where(query_options.join(" AND ")).ids
  end

  def destroy_in_batches(ids)
    ids.in_groups_of(BATCH_SIZE, false) do |batch_ids|
      ActiveRecord::Base.transaction do
        Metric.where(id: batch_ids).destroy_all
      end
    end
  end
end
