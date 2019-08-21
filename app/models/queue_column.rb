# frozen_string_literal: true

class QueueColumn
  include ActiveModel::Model

  validates :name, :sorting_table, :sorting_columns, presence: true

  attr_accessor :name, :sorting_table, :sorting_columns, :filter_function

  # TODO: Validate filter_function is in our acceptable set of filters

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

  # TODO: Consider renaming to be more specific to the context we are working in.
  def to_hash(tasks)
    return { name: name, filterable: false, filter_options: nil } if filter_function.nil?

    {
      name: name,
      filterable: true,
      filter_options: send(filter_function.to_sym, tasks)
    }
  end

  private

  def filter_docket_type(tasks)
    arr = []

    tasks.joins(CachedAppeal.left_join_from_tasks_clause).group(:docket_type).count.each_pair do |option, count|
      arr << { value: option, label: format("%s (%d)", Constants::DOCKET_NAME_FILTERS[option], count) }
    end

    arr
  end

  def filter_task_type(tasks)
    arr = []

    tasks.group(:type).count.each_pair do |option, count|
      arr << { value: option, label: format("%s (%d)", Object.const_get(option).label, count) }
    end

    arr
  end

  def filter_regional_office(tasks)
    arr = []

    tasks.joins(CachedAppeal.left_join_from_tasks_clause)
      .group(:closest_regional_office_city).count.each_pair do |option, count|
      # TODO: Double encode these values
      arr << { value: option, label: format("%s (%d)", option, count) }
    end

    arr
  end

  def filter_case_type(tasks)
    arr = []

    # Add the AOD option first.
    aod_counts = tasks.joins(CachedAppeal.left_join_from_tasks_clause).group(:is_aod).count
    arr << { value: "is_aod", label: format("%s (%d)", "AOD", aod_counts[true]) }

    tasks.joins(CachedAppeal.left_join_from_tasks_clause).group(:case_type).count.each_pair do |option, count|
      # TODO: Map the label to the correct friendly name.
      arr << { value: option, label: format("%s (%d)", option, count) }
    end

    arr
  end
end
