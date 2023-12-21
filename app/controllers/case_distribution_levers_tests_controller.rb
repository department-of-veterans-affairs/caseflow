require 'csv'

class CaseDistributionLeversTestsController < ApplicationController
  before_action :set_user, only: [:add_user, :remove_user, :make_admin, :remove_admin]
  before_action :check_environment

  def acd_lever_index_test
    @acd_levers = CaseDistributionLever.all
    @acd_history = CaseDistributionAuditLeverEntry.past_year

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

  def appeals_ready_to_distribute
    results = AppealsReadyForDistribute.process

    # Get the current date and time for dynamic filename
    current_datetime = Time.now.strftime('%Y%m%d-%H%M')

    # Convert results to CSV format

    csv_data = CSV.generate(headers: true) do |csv|
      # Add headers to CSV
      csv << ['UUID']

      # Iterate through results and add each row to CSV
      results.each do |record|
        csv << [record.uuid]
      end
    end

    # Set dynamic filename with current date and time
    filename = "appeals_ready_to_distribute_#{current_datetime}.csv"

    # Send CSV as a response with dynamic filename
    send_data csv_data, filename: filename
  end

  def appeals_distributed
    # change this to the correct class
    results = BatchAppealsForReaderQuery.process

    # Get the current date and time for dynamic filename
    current_datetime = Time.now.strftime('%Y%m%d-%H%M')

    # Convert results to CSV format
    csv_data = CSV.generate(headers: true) do |csv|
      # Add headers to CSV
      csv << ['CSS ID', 'Full Name', 'Status']

      # Iterate through results and add each row to CSV
      results.each do |record|
        csv << [record[0].css_id, record[0].full_name, record[0].status]
      end
    end

    # Set dynamic filename with current date and time
    filename = "distributed_appeals_#{current_datetime}.csv"

    # Send CSV as a response with dynamic filename
    send_data csv_data, filename: filename
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
