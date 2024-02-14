# frozen_string_literal: true

class CorrespondenceQueueColumn < QueueColumn
  def to_hash(_tasks)
    {
      name: name,
      filterable: false,
      filter_options: []
    }
  end
end
