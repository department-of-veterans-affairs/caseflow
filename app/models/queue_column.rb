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

  # :reek:FeatureEnvy
  # Issue Type helpers to expand issue type filter options to all possible options for orgs that support it
  def all_possible_issue_type_options(tasks)
    assigned_to = extract_assigned_to_from_relation(tasks)
    # Can add more orgs/users if neccessary to limit the possible issue categories in the available options
    # E.g. Add Issue Category1(0), Issue Category2(0) into the options if they aren't on the tasks in the tab
    if assigned_to.is_a?(VhaCamo) || assigned_to.is_a?(VhaRegionalOffice) || assigned_to.is_a?(VhaProgramOffice)
      Constants.ISSUE_CATEGORIES.vha.reject { |category| category.match?(/caregiver/i) }
    elsif assigned_to.is_a?(VhaCaregiverSupport)
      Constants.ISSUE_CATEGORIES.vha.select { |category| category.match?(/caregiver/i) }
    end
  end

  def extract_assigned_to_from_relation(tasks)
    where_hash = tasks.where_values_hash
    # Try to grab assigned to from the task association.
    # If it's not available, then extract it from the active record relation object
    tasks&.first&.assigned_to ||
      where_hash["assigned_to_type"].try(:constantize)&.find_by(id: where_hash["assigned_to_id"])
  end

  # :reek:FeatureEnvy
  def add_empty_issue_types_to_filter_list(tasks, totals)
    # Get the extra issue types from the ISSUE_CATEGORIES json
    extra_issue_types = all_possible_issue_type_options(tasks)
    updated_totals = totals.dup

    # If there are extra issues merge them in to the totals hash. e.g. Other => 0
    extra_issue_types&.each do |key|
      updated_totals[key] = updated_totals[key] || 0
    end

    updated_totals
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

    # Add in extra options if the org supports it. e.g. Other (0)
    extra_issue_types = add_empty_issue_types_to_filter_list(tasks, totals)

    extra_issue_types.each_pair.map do |option, count|
      label = self.class.format_option_label(option, count)
      self.class.filter_option_hash(option, label)
    end
  end
end
