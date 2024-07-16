# frozen_string_literal: true

class LoadTestingController < ApplicationController
  def index
    render json: {
      feature_toggles_available: { name: "name", default_status: "true or false" },
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

  # Only accessible non-prod environment
  def check_environment
    return render status: :not_found if Rails.deploy_env == :production
  end
end
