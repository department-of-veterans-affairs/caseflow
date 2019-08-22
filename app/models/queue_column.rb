# frozen_string_literal: true

class QueueColumn
  include ActiveModel::Model

  validates :name, :sorting_table, :sorting_columns, presence: true
  validate :filter_function_is_valid

  attr_accessor :name, :sorting_table, :sorting_columns, :filter_function

  def initialize(args)
    super

    @sorting_table ||= Task.table_name
    @sorting_columns ||= ["created_at"]

    fail(Caseflow::Error::MissingRequiredProperty, message: errors.full_messages.join(", ")) unless valid?
  end

  def self.from_name(column_name)
    column_config = Constants.QUEUE_CONFIG.COLUMNS.to_h.values.find { |col| col[:name] == column_name }

    column_config ? new(column_config) : nil
  end

  def to_hash(tasks)
    return { name: name, filterable: false, filter_options: nil } if filter_function.nil?

    {
      name: name,
      filterable: true,
      filter_options: send(filter_function.to_sym, tasks)
    }
  end

  private

  # rubocop:disable Style/FormatStringToken
  def format_option_label(label, count)
    format("%s (%d)", label, count)
  end
  # rubocop:enable Style/FormatStringToken

  def filter_option_hash(value, label)
    # Double encode the values here since we un-encode them twice in QueueFilterParameter. Once when parsing the query
    # and again when unpacking the values of the selected filters into an array.
    { value: URI.escape(URI.escape(value)), label: label }
  end

  def filter_docket_type(tasks)
    tasks.joins(CachedAppeal.left_join_from_tasks_clause).group(:docket_type).count.each_pair.map do |option, count|
      label = format_option_label(Constants::DOCKET_NAME_FILTERS[option], count)
      filter_option_hash(option, label)
    end
  end

  def filter_task_type(tasks)
    tasks.group(:type).count.each_pair.map do |option, count|
      label = format_option_label(Object.const_get(option).label, count)
      filter_option_hash(option, label)
    end
  end

  def filter_regional_office(tasks)
    tasks.joins(CachedAppeal.left_join_from_tasks_clause)
      .group(:closest_regional_office_city).count.each_pair.map do |option, count|
      label = format_option_label(option, count)
      filter_option_hash(option, label)
    end
  end

  def filter_case_type(tasks)
    options = tasks.joins(CachedAppeal.left_join_from_tasks_clause)
      .group(:case_type).count.each_pair.map do |option, count|
      # TODO: Map the label to the correct friendly name.
      label = format_option_label(option, count)
      arr << filter_option_hash(option, label)
    end

    # Add the AOD option as the first option in the list.
    aod_counts = tasks.joins(CachedAppeal.left_join_from_tasks_clause).group(:is_aod).count
    aod_option_label = format_option_label("AOD", aod_counts[true])

    [filter_option_hash("is_aod", aod_option_label)] + options
  end

  def filter_function_is_valid
    valid_filter_functions = [
      Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.filter_function,
      Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.filter_function,
      Constants.QUEUE_CONFIG.COLUMNS.REGIONAL_OFFICE.filter_function,
      Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.filter_function
    ]

    if !filter_function.nil? && !valid_filter_functions.include?(filter_function)
      errors.add(:assignee, COPY::INVALID_FILTER_FUNCTION)
    end
  end
end
