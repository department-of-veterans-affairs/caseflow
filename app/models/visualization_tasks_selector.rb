# frozen_string_literal: true

class VisualizationTasksSelector
  include ActiveModel::Model

  validates :organization_id, presence: true

  attr_accessor :organization_id, :filter_params

  def initialize(args)
    super

    fail Caseflow::Error::MissingRequiredProperty, message: "Organization ID is required" unless valid?
  end

  def tasks
    filtered_tasks = all_tasks

    filter_params&.keys&.each do |filter_key|
      filtered_tasks = filtered_tasks.where("#{filter_key} = ?", filter_params[filter_key])
    end

    all_tasks
  end

  def all_tasks
    Task.where(assigned_to_type: User.name, parent_id: parent_tasks.pluck(:id))
  end

  def parent_tasks
    Task.where(assigned_to_type: Organization.name, assigned_to_id: organization_id)
  end
end
