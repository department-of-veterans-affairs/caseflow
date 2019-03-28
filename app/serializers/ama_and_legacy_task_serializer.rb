# frozen_string_literal: true

class AmaAndLegacyTaskSerializer
  def initialize(tasks:, params:, ama_serializer:)
    @tasks = tasks
    @params = params
    @ama_serializer = ama_serializer
  end

  def call
    legacy_tasks, ama_tasks = tasks.partition { |task| task.is_a? LegacyTask }

    legacy_tasks_hash = WorkQueue::LegacyTaskSerializer.new(
      legacy_tasks, is_collection: true, params: params
    ).serializable_hash[:data]

    ama_tasks_hash = ama_serializer.new(
      ama_tasks, is_collection: true, params: params
    ).serializable_hash[:data]

    { data: legacy_tasks_hash.concat(ama_tasks_hash) }
  end

  private

  attr_reader :tasks, :params, :ama_serializer
end
