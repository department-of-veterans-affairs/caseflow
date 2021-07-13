# frozen_string_literal: true

class TaskPolicy
  def initialize(user:, resource:)
    @user = user
    @resource = resource
  end

  def assigned_to
    if restrict_vso?
      nil
    else
      @resource.assigned_to
    end
  end

  private

  attr_reader :user, :resource

  def restrict_vso?
    FeatureToggle.enabled?(:restrict_poa_visibility, user: @user) && @user.vso_employee?
  end
end
