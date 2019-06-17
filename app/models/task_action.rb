# frozen_string_literal: true

class TaskAction
  include ActiveModel::Model

  def initialize(config, task, user)
    @label = config[:label]
    @value = config[:value]

    build_data_attribute(config[:func], task, user)
  end

  def to_h
    {
      label: @label,
      value: @value,
      data: @data
    }
  end

  private

  def build_data_attribute(func, task, user)
    data = func ? TaskActionRepository.send(func, task, user) : nil
    @data = data

    if data&.delete(:returns_complete_hash)
      @label = data[:label]
      @value = data[:value]
      @data = data[:data]
    end
  end
end
