class CaseDistributionLeversTestsController < ApplicationController
  before_action :set_user, only: [:add_user, :remove_user, :make_admin, :remove_admin]
  before_action :check_environment

  def acd_lever_index_test
    @acd_levers = CaseDistributionLever.all
    @acd_history = CaseDistributionAuditLeverEntry.past_year
    @acd_algorithm_history = CaseDistributionAlgorithmLog.past_year

    render "case_distribution_levers/test"
  end

  def create_acd_group_org_singleton
    CDAControlGroup.singleton

    reload_page
  end

  def destroy_acd_group_org
    CDAControlGroup.singleton.destroy

    reload_page
  end

  def add_user
    CDAControlGroup.singleton.add_user(@user)

    reload_page
  end

  def remove_user
    OrganizationsUser.remove_user_from_organization(@user, CDAControlGroup.singleton)

    reload_page
  end

  def make_admin
    OrganizationsUser.make_user_admin(@user, CDAControlGroup.singleton)

    reload_page
  end

  def remove_admin
    OrganizationsUser.remove_admin_rights_from_user(@user, CDAControlGroup.singleton)

    reload_page
  end

  private
  def set_user
    if params["user"]
      @user = User.find(params["user"])
    end
  end

  def reload_page
    redirect_back(fallback_location: "case_distribution_levers/test")
  end

  def check_environment
    return true if Rails.env.development?
    return true if Rails.deploy_env?(:demo)

    redirect_to "/unauthorized"
  end
end
