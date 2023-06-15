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

  FILTER_OPTIONS = {
    Constants.QUEUE_CONFIG.COLUMNS.APPEAL_TYPE.name => :case_type_options,
    Constants.QUEUE_CONFIG.COLUMNS.DOCKET_NUMBER.name => :docket_type_options,
    Constants.QUEUE_CONFIG.COLUMNS.REGIONAL_OFFICE.name => :regional_office_options,
    Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name => :task_type_options,
    Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name => :assignee_options,
    Constants.QUEUE_CONFIG.COLUMNS.ISSUE_TYPES.name => :issue_type_options
  }.freeze

  def filter_options(tasks)
    filter_option_func = FILTER_OPTIONS[name]
    if filter_option_func
      send(filter_option_func, tasks)
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
    { value: URI::DEFAULT_PARSER.escape(URI::DEFAULT_PARSER.escape(value)), displayText: label }
  end

  private

  def case_type_options(tasks)
    options = tasks.with_cached_appeals.group(:case_type).count.each_pair.map do |option, count|
      label = self.class.format_option_label(option, count)
      self.class.filter_option_hash(option, label)
    end

    # Add the AOD option as the first option in the list.
    aod_counts = tasks.with_cached_appeals.group(:is_aod).count[true]
    if aod_counts
      aod_option_key = Constants.QUEUE_CONFIG.FILTER_OPTIONS.IS_AOD.key
      aod_option_label = self.class.format_option_label("AOD", aod_counts)
      options = [self.class.filter_option_hash(aod_option_key, aod_option_label)] + options
    end

    options
  end

  def docket_type_options(tasks)
    tasks.with_cached_appeals.group(:docket_type).count.each_pair.map do |option, count|
      label = self.class.format_option_label(Constants::DOCKET_NAME_FILTERS[option], count)
      self.class.filter_option_hash(option, label)
    end
  end

  def regional_office_options(tasks)
    tasks.with_cached_appeals.group(:closest_regional_office_city).count.each_pair.map do |option, count|
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
    tasks.with_assignees.group("assignees.display_name").count(:all).each_pair.map do |option, count|
      label = self.class.format_option_label(option, count)
      self.class.filter_option_hash(option, label)
    end
  end

  # Helper for issue type options
  def all_possible_issue_type_options(tasks)
    assigned_to = tasks.first.assigned_to
    # Can add more orgs to this if needed
    if assigned_to.is_a?(VhaCamo || VhaRegionalOffice || VhaProgramOffice)
      Constants.ISSUE_CATEGORIES.vha.reject { |category| category.match?(/caregiver/i) }
    elsif assigned_to.is_a?(VhaCaregiverSupport)
      Constants.ISSUE_CATEGORIES.vha.select { |category| category.match?(/caregiver/i) }
    end
  end

  # Another issue type helper
  def add_empty_issue_types_to_filter_list(tasks, totals)
    # Get the extra issue types from the ISSUE_CATEGORIES json
    extra_issue_types = all_possible_issue_type_options(tasks)
    # If there are extra issues merge them in to the totals hash. e.g. Other => 0
    if extra_issue_types
      extra_issue_types.each do |key|
        count = totals[key] || 0
        merged[key] = count
      end
      extra_issue_types.each_with_object({}) do |key, merged|
        count = totals[key] || 0
        merged[key] = count
      end
    else
      # If there are no extra issue types then just return the normal count
      totals
    end
  end

  def issue_type_options(tasks)
    count_hash = tasks.with_cached_appeals.group(:issue_types).count
    totals = Hash.new(0)

    count_hash.each do |key, value|
      if key.blank?
        totals[Constants.QUEUE_CONFIG.BLANK_FILTER_KEY_VALUE] += value.to_i
      else
        key.split(",").each do |string|
          totals[string.strip] += value.to_i
        end
      end
    end

    extra_issue_types = add_empty_issue_types_to_filter_list(tasks, totals)

    extra_issue_types.each_pair.map do |option, count|
      label = self.class.format_option_label(option, count)
      self.class.filter_option_hash(option, label)
    end
  end
end
