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

    ids_to_delete = metric_ids

    destroy_in_batches(ids_to_delete) unless ids_to_delete.blank?
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
    option_names = []
    option_values = []

    @options.each do |name, value|
      case name
      when :metric_type
        option_names << "metric_type = ?"
        option_values << value
      when :months
        option_names << "created_at < ?"
        option_values << value
      when :metric_product
        option_names << "metric_product = ?"
        option_values << value
      when :metric_message
        option_names << "metric_message ILIKE ?"
        option_values << value
      end
    end

    Metric.where(option_names.join(" AND "), *option_values).ids
  end

  def destroy_in_batches(ids)
    ids.in_groups_of(BATCH_SIZE, false) do |batch_ids|
      ActiveRecord::Base.transaction do
        Metric.where(id: batch_ids).destroy_all
      end
    end
  end
end
