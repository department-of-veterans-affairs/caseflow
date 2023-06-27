# frozen_string_literal: true

class CancelTasksAndDescendants
  # @param task_relation [ActiveRecord::Relation] tasks to be cancelled
  # @return [NilClass]
  def self.call(task_relation = Task.none)
    new(task_relation).__send__(:call)
  end

  private

  def initialize(task_relation)
    @task_relation = task_relation
  end

  def call
    RequestStore[:current_user] = User.system_user

    @task_relation.find_each do |task|
      task.cancel_task_and_child_subtasks
    rescue StandardError => error
    end
  end

  class VeteranRecordRequestsOpenForVREQuery
    VRE_BUSINESS_LINE_NAME = "Veterans Readiness and Employment"

    # @return [ActiveRecord::Relation] VeteranRecordRequest tasks that are
    #   both open and assigned to the VRE business line
    def self.call
      vre_business_line = BusinessLine.where(name: VRE_BUSINESS_LINE_NAME)
      VeteranRecordRequest.open.where(assigned_to: vre_business_line)
    end
  end
end
