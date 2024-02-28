# frozen_string_literal: true

class CorrespondenceQueueColumn < QueueColumn
  include ActiveModel::Model

  attr_accessor :filterable, :name

  def initialize(args)
    super
    @filterable ||= false
  end

  def to_hash(tasks)
    {
      name: name,
      filterable: filterable,
      filter_options: filterable ? filter_options(tasks) : []
    }
  end

  FILTER_OPTIONS = {
    Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name => :task_type_options,
    Constants.QUEUE_CONFIG.COLUMNS.VA_DATE_OF_RECEIPT.name => :va_dor_options,
    Constants.QUEUE_CONFIG.COLUMNS.TASK_CLOSED_DATE.name => :date_completed_options,
    Constants.QUEUE_CONFIG.COLUMNS.TASK_ASSIGNEE.name => :task_type_options
  }.freeze

  private

  def task_type_options(tasks)
    tasks.group(:type).count.each_pair.map do |option, count|
      label = self.class.format_option_label(Object.const_get(option).label, count)
      self.class.filter_option_hash(option, label)
    end
  end

  # placeholder method because the function is required
  def va_dor_options(dummy)
    dummy
  end

  def date_completed_options(dummy)
    dummy
  end
end
