# This will allow the output of the log information to be printed to the console screen
# when the task is run using 'rake war_room:dupp_ep_claims_sync_status_update_can_clr'.
# It's a logger to provide visibility into what the rake task is doing.
# The logger is set to write to standard output (STDOUT).
# Initializing an instance of WarRoom::DuppEpClaimsSyncStatusUpdateCanClr and using it to retrieve the problem reviews and resolve any duplicate end products.
# Adding logging messages at the start and end of the rake task to indicate when it begins and completes.
# This implementation assumes that the RequestStore and ActiveRecord::Base configurations are properly set up in the Rails application's environment.

namespace :war_room do
  desc "Process DuppEpClaimsSyncStatusUpdateCanClr"
  task dupp_ep_claims_sync_status_update_can_clr: :environment do
    logger = Logger.new(STDOUT)

    logger.info("Starting DuppEpClaimsSyncStatusUpdateCanClr rake task")

    RequestStore[:current_user] = OpenStruct.new(
      ip_address: '127.0.0.1',
      station_id: '283',
      css_id: 'CSFLOW',
      regional_office: 'DSUSER'
    )

    war_room = WarRoom::DuppEpClaimsSyncStatusUpdateCanClr.new

    problem_reviews = war_room.retrieve_problem_reviews

    if problem_reviews.count.zero?
      logger.info("No problem Supplemental Claims or Higher Level Reviews found. Exiting.")
      return false
    end

    ActiveRecord::Base.transaction do
      war_room.resolve_duplicate_eps(problem_reviews)
    end

    logger.info("Completed DuppEpClaimsSyncStatusUpdateCanClr rake task")
  end
end
