# frozen_string_literal: true

class TaskAction
  include ActiveModel::Model

  def initialize(config, task, user)
    @task = task
    @user = user

    @label = config[:label]
    @value = config[:value]

    build_data_attribute(config[:func])
  end

  def to_h
    {
      label: @label,
      value: @value,
      data: @data
    }
  end

  private

  def build_data_attribute(func)
    data = func ? TaskActionRepository.send(func, @task, @user) : nil

    if data&.delete(:returns_complete_hash)
      @label = data[:label]
      @value = data[:value]
    end

    @data = data
  end
end
