# frozen_string_literal: true

class TaskAction
  include ActiveModel::Model

  def initialize(config, task, user)
    @task = task
    @user = user

    @label = config[:label]
    @value = config[:value]

    @func = config[:func]
  end

  def to_h
    data = @func ? TaskActionRepository.send(@func, @task, @user) : nil
    return data if data&.delete(:returns_complete_hash)

    {
      label: @label,
      value: @value,
      data: data
    }
  end
end
