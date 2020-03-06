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

  def self.create_and_preload_legacy_appeals(tasks:, params:, ama_serializer: WorkQueue::TaskSerializer)
    tasks = AppealRepository.eager_load_legacy_appeals_for_tasks(tasks)

    AmaAndLegacyTaskSerializer.new(tasks: tasks, params: params, ama_serializer: ama_serializer)
  end

  private

  attr_reader :tasks, :params, :ama_serializer
end
