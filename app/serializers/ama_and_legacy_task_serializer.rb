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

    # byebug
    puts "--------------------------- In call method for ama and legacy task serializer ---------------------------"
    start_time1 = Time.zone.now
    ama_tasks_hash = {}
    p ama_serializer.name

    begin
      StackProf.run(mode: :wall, out: "ama_serializer_call.dump") do
        ama_tasks_hash = ama_serializer.new(
          ama_tasks, is_collection: true, params: params
        ).serializable_hash[:data]
      end
    rescue StandardError => error
      # Print the error message and stack trace
      puts "An error occurred: #{error.message}"
      puts error.backtrace.join("\n")
    end

    end_time1 = Time.zone.now
    # puts ama_tasks.count
    puts "Ama serialize took: #{(end_time1 - start_time1) * 1000}"
    # byebug

    { data: legacy_tasks_hash.concat(ama_tasks_hash) }
  end

  def self.create_and_preload_legacy_appeals(tasks:, params:, ama_serializer: WorkQueue::TaskSerializer)
    # tasks = AppealRepository.eager_load_legacy_appeals_for_tasks(tasks)
    testing_appeal_includes =
      [
        {
          appeal: [
            :available_hearing_locations,
            :claimants,
            :work_mode,
            :latest_informal_hearing_presentation_task,
            :request_issues,
            :special_issue_list,
            :decision_issues,
            :appeal_views
          ]
        },
        :assigned_by,
        :assigned_to,
        :children,
        :parent,
        :attorney_case_reviews,
        :cancelled_by,
        :completed_by
      ]

    # tasks = if tasks.is_a?(Array)
    #           AppealRepository.eager_load_legacy_appeals_for_tasks(tasks)
    #         else
    #           # puts "should see this for"
    #           # puts tasks.to_sql
    #           # Attempt at preloading for judges. Attorney comes in as an array and so would need to be handled
    #           # In a different way than it currently works in the AppealRepo
    #           AppealRepository.eager_load_legacy_appeals_for_tasks_in_queue(tasks, testing_appeal_includes)
    #           # AppealRepository.eager_load_legacy_appeals_for_tasks(tasks)
    #         end
    tasks = AppealRepository.eager_load_legacy_appeals_for_tasks_in_queue(tasks, testing_appeal_includes)
    # byebug
    # tasks = AppealRepository.eager_load_legacy_appeals_for_tasks_in_queue(tasks, testing_appeal_includes)

    AmaAndLegacyTaskSerializer.new(tasks: tasks, params: params, ama_serializer: ama_serializer)
  end

  private

  attr_reader :tasks, :params, :ama_serializer
end
