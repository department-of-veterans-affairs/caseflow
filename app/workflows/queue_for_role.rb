# frozen_string_literal: true

class QueueForRole
  def initialize(user_role)
    if user_role.nil?
      fail ArgumentError, "expected user role"
    end

    @user_role = user_role
  end

  def create(**args)
    (user_role == "attorney") ? AttorneyQueue.new(**args) : GenericQueue.new(**args)
  end

  private

  attr_reader :user_role
end
