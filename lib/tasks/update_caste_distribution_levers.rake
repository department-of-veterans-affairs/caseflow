# frozen_string_literal: true

# to update ama remand reasons code for existing records in db
# run "bundle exec rails case_distribution_levers:update_item"

namespace :case_distribution_levers do
  desc "Update case distribution levers for existing records in db"
  task update_item: :environment do
    puts "Started case distribution lever update #{Time.current}"
    CaseDistributionLever.find_by_item("ama_hearings_docket_time_goals")
      .update!(item: "ama_hearing_docket_time_goals")
    CaseDistributionLever.find_by_item("ama_hearings_start_distribution_prior_to_goals")
      .update!(item: "ama_hearing_start_distribution_prior_to_goals")
    puts "Completed case distribution lever update #{Time.current}"
  end

  # revert item task is added to use incase of a rollback during production release
  desc "Revert case distribution levers for existing records in db"
  task revert_item: :environment do
    puts "Started reverting case distribution lever item #{Time.current}"
    CaseDistributionLever.find_by_item("ama_hearing_docket_time_goals")
      .update!(item: "ama_hearings_docket_time_goals")
    CaseDistributionLever.find_by_item("ama_hearing_start_distribution_prior_to_goals")
      .update!(item: "ama_hearings_start_distribution_prior_to_goals")
    puts "Reverted case distribution lever item #{Time.current}"
  end
end
