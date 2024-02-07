# frozen_string_literal: true

class CorrespondenceQueueColumn < QueueColumn
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
    Constants.QUEUE_CONFIG.COLUMNS.VETERAN_DETAILS.name => :filter_by_veteran_details

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

def filter_by_veteran_details(tasks)
  tasks.map do |task|
    appeal = task.appeal
    {
      name: task.appeal.veteran.name
    }
  end
end
