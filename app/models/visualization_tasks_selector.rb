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
    Task.where(assigned_to_type: User.name)
  end
end
