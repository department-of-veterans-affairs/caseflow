# frozen_string_literal: true

require "./scripts/enable_features_dev.rb"
class Test::LoadTestingController < ApplicationController
  before_action :check_environment

  def index
    render json: {
      feature_toggles_available: find_features.map { |key, value| { name: key, default_status: value } },
      functions_available: find_functions,
      all_csum_roles: find_roles,
      all_organizations: find_orgs
    }
  end

  private

  def find_features
    all_features = AllFeatureToggles.new.call.flatten.uniq.sort
    all_features.map! { |feature| feature.split(",")[0] }
    all_features.map! { |feature| [feature, FeatureToggle.enabled?(feature)] }.to_h
  end

  def find_functions
    Functions.list_all.keys.sort
  end

  def find_roles
    User.all.pluck(:roles).flatten.uniq.compact.sort
  end

  def find_orgs
    Organization.pluck(:name).sort
  end

  # Only accessible from non-prod environment
  def check_environment
    return render status: :not_found if Rails.deploy_env == :production
  end
end
