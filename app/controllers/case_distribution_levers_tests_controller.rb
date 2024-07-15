# frozen_string_literal: true

require "csv"

class CaseDistributionLeversTestsController < ApplicationController
  before_action :check_environment

  def acd_lever_index_test
    @acd_levers = CaseDistributionLever.all
    @acd_history = CaseDistributionAuditLeverEntry.lever_history

    render "case_distribution_levers/test"
  end

  def run_demo_non_aod_hearing_seeds
    Rake::Task["db:seed:demo_non_aod_hearing_case_lever_test_data"].reenable
    Rake::Task["db:seed:demo_non_aod_hearing_case_lever_test_data"].invoke

    head :ok
  end

  def run_demo_aod_hearing_seeds
    Rake::Task["db:seed:demo_aod_hearing_case_lever_test_data"].reenable
    Rake::Task["db:seed:demo_aod_hearing_case_lever_test_data"].invoke

    head :ok
  end

  def appeals_ready_to_distribute
    csv_data = AppealsReadyForDistribution.process

    # Get the current date and time for dynamic filename
    current_datetime = Time.zone.now.strftime("%Y%m%d-%H%M")

    # Set dynamic filename with current date and time
    filename = "appeals_ready_to_distribute_#{current_datetime}.csv"

    # Send CSV as a response with dynamic filename
    send_data csv_data, filename: filename
  end

  def appeals_distributed
    # change this to the correct class
    csv_data = AppealsDistributed.process

    # Get the current date and time for dynamic filename
    current_datetime = Time.zone.now.strftime("%Y%m%d-%H%M")

    # Set dynamic filename with current date and time
    filename = "distributed_appeals_#{current_datetime}.csv"

    # Send CSV as a response with dynamic filename
    send_data csv_data, filename: filename
  end

  def ineligible_judge_list
    # change this to the correct class
    csv_data = IneligibleJudgeList.process

    # Get the current date and time for dynamic filename
    current_datetime = Time.zone.now.strftime("%Y%m%d-%H%M")

    # Set dynamic filename with current date and time
    filename = "#{current_datetime}_ineligible_judge_list.csv"

    # Send CSV as a response with dynamic filename
    send_data csv_data, filename: filename
  end

  private

  def check_environment
    return true if Rails.env.development?
    return true if Rails.deploy_env?(:demo)

    redirect_to "/unauthorized"
  end
end
