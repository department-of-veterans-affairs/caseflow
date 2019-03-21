# frozen_string_literal: true

class BulkTaskAssignment
  include ActiveModel::Model

  validates :assign_to, :task_type, :task_count, presence: true

  attr_accessor :assign_to, :task_type, :task_count
end
