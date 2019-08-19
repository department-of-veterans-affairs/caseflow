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
end
