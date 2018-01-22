# Called "WorkQueue" instead of "Queue" to not conflict with the
# "Queue" class that ships with Ruby.
class WorkQueue
  include ActiveModel::Model
  class << self
    attr_writer :repository

    def repository
      @repository ||= QueueRepository
    end
  end
end
