# frozen_string_literal: true

require "./scripts/enable_features_dev.rb"
class LoadTestingController < ApplicationController
  def index
    render json: {
      feature_toggles_available: find_features.map { |key, value| { name: key, default_status: value } },
      functions_available: "all the functions in the system",
      all_csum_roles: find_roles,
      all_organizations: find_orgs
    }
  end

  private

  def find_orgs
    Organization.pluck(:name).sort
  end

  def find_roles
    User.all.pluck(:roles).flatten.uniq.compact.sort
  end

  def find_features
    disabled_flags = %w[
      legacy_das_deprecation
      cavc_dashboard_workflow
      poa_auto_refresh
      interface_version_2
      cc_vacatur_visibility
      acd_disable_legacy_lock_ready_appeals
      justification_reason
    ]
    all_features = AllFeatureToggles.new.call.flatten.uniq
    all_features.map! { |feature| feature.split(",")[0] }
    all_features.sort.each_with_object({}) do |feature, hash|
      hash[feature] = (disabled_flags.include? feature) ? "disabled" : "enabled"
    end
  end

  # Only accessible from non-prod environment
  def check_environment
    return render status: :not_found if Rails.deploy_env == :production
  end
end
