# frozen_string_literal: true

namespace :db do
  desc "sets affinity_start_dates for all appeals that need them"
  task affinity_start_date: :environment do
    dockets = %w[hearing direct_review evidence_submission]
    docket_receipt_dates = []

    # {Gets receipt_date for recent priority distributed appeal in each docket}
    dockets.each do |docket|
      docket_receipt_dates << {
        receipt_date: DistributedCase.where(docket: docket, priority: true)
          .order(created_at: :desc)&.first&.task&.appeal&.receipt_date,
        priority: true,
        docket_type: docket
      }
    end

    # {Gets receipt_date for recent nonpriority distributed appeal in each docket}
    dockets.each do |docket|
      docket_receipt_dates << {
        receipt_date: DistributedCase.where(docket: docket, priority: false)
          .order(created_at: :desc)&.first&.task&.appeal&.receipt_date,
        priority: false,
        docket_type: docket
      }
    end

    # {Each receipt_date is then used here to get correlating appeals}
    docket_receipt_dates.each do |docket_result|
      next if docket_result[:receipt_date].nil?

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
            priority: docket_result[:priority],
            affinity_start_date: Time.zone.now
          )
        end
      end
    end
  end
end
