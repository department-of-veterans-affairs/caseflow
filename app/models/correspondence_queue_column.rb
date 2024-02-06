# frozen_string_literal: true

class CorrespondenceQueueColumn < QueueColumn
  # super
  @filterable ||= false

  def to_hash(tasks)
    {
      name: name,
      filterable: filterable,
      filter_options: filterable ? filter_options(tasks) : []
    }
  end

  FILTER_OPTIONS = {

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

end
