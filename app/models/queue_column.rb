# frozen_string_literal: true

class QueueColumn
  include ActiveModel::Model

  validates :name, :sorting_table, :sorting_columns, presence: true

  attr_accessor :filterable, :name, :sorting_table, :sorting_columns

  def initialize(args)
    super

    @filterable ||= false
    @sorting_table ||= Task.table_name
    @sorting_columns ||= ["created_at"]

    fail(Caseflow::Error::MissingRequiredProperty, message: errors.full_messages.join(", ")) unless valid?
  end

  def self.from_name(column_name)
    column_config = Constants.QUEUE_CONFIG.COLUMNS.to_h.values.find { |col| col[:name] == column_name }

    column_config ? new(column_config) : nil
  end

  def to_hash(tasks)
    {
      name: name,
      filterable: filterable,
      filter_options: filterable ? filter_options(tasks) : []
    }
  end

  def filter_options(tasks)
    case name
    when Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name
      case_type_options(tasks)
    when Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name
      docket_type_options(tasks)
    when Constants.QUEUE_CONFIG.COLUMNS.REGIONAL_OFFICE.name
      regional_office_options(tasks)
    when Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name
      task_type_options(tasks)
    when Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name
      assignee_options(tasks)
    else
      fail(
        Caseflow::Error::MustImplementInSubclass,
        "Filterable tasks must have an associated function to collect filter options"
      )
    end
  end

  # rubocop:disable Style/FormatStringToken
  def self.format_option_label(label, count)
    label ||= COPY::NULL_FILTER_LABEL
    format("%s (%d)", label, count)
  end
  # rubocop:enable Style/FormatStringToken

  def self.filter_option_hash(value, label)
    value ||= COPY::NULL_FILTER_LABEL
    # Double encode the values here since we un-encode them twice in QueueFilterParameter. Once when parsing the query
    # and again when unpacking the values of the selected filters into an array.
    { value: URI.escape(URI.escape(value)), displayText: label }
  end

  private

  def case_type_options(tasks)
    options = tasks.joins(CachedAppeal.left_join_from_tasks_clause)
      .group(:case_type).count.each_pair.map do |option, count|
      label = self.class.format_option_label(option, count)
      self.class.filter_option_hash(option, label)
    end

    # Add the AOD option as the first option in the list.
    aod_counts = tasks.joins(CachedAppeal.left_join_from_tasks_clause).group(:is_aod).count[true]
    if aod_counts
      aod_option_key = Constants.QUEUE_CONFIG.FILTER_OPTIONS.IS_AOD.key
      aod_option_label = self.class.format_option_label("AOD", aod_counts)
      options = [self.class.filter_option_hash(aod_option_key, aod_option_label)] + options
    end

    options
  end

  def docket_type_options(tasks)
    tasks.joins(CachedAppeal.left_join_from_tasks_clause).group(:docket_type).count.each_pair.map do |option, count|
      label = self.class.format_option_label(Constants::DOCKET_NAME_FILTERS[option], count)
      self.class.filter_option_hash(option, label)
    end
  end

  def regional_office_options(tasks)
    tasks.joins(CachedAppeal.left_join_from_tasks_clause)
      .group(:closest_regional_office_city).count.each_pair.map do |option, count|
      label = self.class.format_option_label(option, count)
      self.class.filter_option_hash(option, label)
    end
  end

  def task_type_options(tasks)
    tasks.group(:type).count.each_pair.map do |option, count|
      label = self.class.format_option_label(Object.const_get(option).label, count)
      self.class.filter_option_hash(option, label)
    end
  end

  def assignee_options(tasks)
    tasks.joins(CachedAppeal.left_join_from_tasks_clause)
      .group(:assignee_label).count.each_pair.map do |option, count|
      label = self.class.format_option_label(option, count)
      self.class.filter_option_hash(option, label)
    end
  end
end
