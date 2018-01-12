class BaseQueue
  include ActiveModel::Model
  class << self
    attr_writer :repository

    def repository
      @repository ||= QueueRepository
    end
  end
end
