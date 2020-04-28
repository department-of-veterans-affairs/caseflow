# frozen_string_literal: true

class QueueForRole
  QUEUE_ROLE_MAPPER = {
    attorney: AttorneyQueue,
    judge: JudgeQueue
  }.freeze

  def initialize(user_role)
    if user_role.nil?
      fail ArgumentError, "expected user role"
    end

    @user_role = user_role
  end

  def create(**args)
    queue = QUEUE_ROLE_MAPPER[user_role.to_sym]
    queue ? queue.new(**args) : GenericQueue.new(**args)
  end

  private

  attr_reader :user_role
end
