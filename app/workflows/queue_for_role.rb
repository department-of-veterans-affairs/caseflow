# frozen_string_literal: true

class QueueForRole
<<<<<<< HEAD
=======
  QUEUE_ROLE_MAPPER = {
    attorney: AttorneyQueue,
    judge: JudgeQueue
  }.freeze

>>>>>>> a49969dbe1f4832cadb3375715210570c8b8440d
  def initialize(user_role)
    if user_role.nil?
      fail ArgumentError, "expected user role"
    end

    @user_role = user_role
  end

  def create(**args)
    queue.new(**args)
  end

  private

  def queue
    case user_role
    when "attorney"
      AttorneyQueue
    when "judge"
      JudgeQueue
    else
      GenericQueue
    end
  end

  attr_reader :user_role
end
