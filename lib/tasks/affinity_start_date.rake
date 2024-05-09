# frozen_string_literal: true

namespace :db do
  desc "sets affinity_start_dates for all appeals that need them"
  # {Can do it this way or create a class and seperate into seperate methods for readability}
  task affinity_start_date: :environment do
    dockets = %w[hearing direct_review evidence_submission]
    docket_results = []

    # {Gets receipt_date for recent priority distributed appeal in each docket}
    dockets.each do |docket|
      docket_results << {
        receipt_date: DistributedCase.where(docket: docket, priority: true)&.first&.task&.appeal&.receipt_date,
        priority: true,
        docket_type: docket
      }
    end

    # {Gets receipt_date for recent nonpriority distributed appeal in each docket}
    dockets.each do |docket|
      docket_results << {
        receipt_date: DistributedCase.where(docket: docket, priority: false)&.first&.task&.appeal&.receipt_date,
        priority: false,
        docket_type: docket
      }
    end

    # {Each receipt_date is then used here to get correlating appeals}
    docket_results.each do |docket_result|
      appeals_to_update = Appeal.extending(DistributionScopes)
        .with_appeal_affinities
        .ready_for_distribution
        .where(docket_type: docket_result[:docket_type])
        .where("appeal_affinities.affinity_start_date <= (?) OR appeal_affinities.case_id IS NULL", docket_result[:receipt_date])

      appeals_to_update_adjusted_for_priority = if docket_result[:priority] == true
                                                  appeals_to_update.priority
                                                else
                                                  appeals_to_update.nonpriority
                                                end

      # {Updates or creates appeals affinity record}
      appeals_to_update_adjusted_for_priority.map do |appeal|
        existing_affinity = appeal.appeal_affinity

        if existing_affinity
          existing_affinity.update!(affinity_start_date: Time.zone.now)
          existing_affinity
        else
          appeal.create_appeal_affinity!(
            docket: appeal.docket_type,
            priority: priority,
            affinity_start_date: Time.zone.now,
            distribution_id: @distribution_id
          )
        end
      end
    end
  end
end
