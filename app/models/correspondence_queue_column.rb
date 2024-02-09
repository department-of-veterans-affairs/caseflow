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
    Constants.QUEUE_CONFIG.COLUMNS.TASK_TYPE.name => :task_type_options

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

private

def task_type_options(tasks)
  tasks.group(:type).count.each_pair.map do |option, count|
    label = self.class.format_option_label(Object.const_get(option).label, count)
    self.class.filter_option_hash(option, label)
  end
end

end
