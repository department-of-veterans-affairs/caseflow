# frozen_string_literal: true

namespace :db do
  desc "sets affinity_start_dates for all appeals that need them"
  task affinity_start_date: :environment do
    priority_dockets = %w[hearing direct_review evidence_submission]
    nonpriority_dockets = %w[hearing]
    docket_receipt_dates = []

    # {Gets receipt_date for recent priority distributed appeal in each docket}
    priority_dockets.each do |docket|
      docket_receipt_dates << {
        receipt_date: DistributedCase.joins("inner join appeals on appeals.uuid::text = distributed_cases.case_id")
          .where(docket: docket, priority: true)
          .where("distributed_cases.created_at >= ?", 1.week.ago)
          .order("appeals.receipt_date desc")
          &.first&.task&.appeal&.receipt_date,
        priority: true,
        docket_type: docket
      }
    end

    # {Gets receipt_date for recent nonpriority distributed appeal in each docket}
    nonpriority_dockets.each do |docket|
      docket_receipt_dates << {
        receipt_date: DistributedCase.joins("inner join appeals on appeals.uuid::text = distributed_cases.case_id")
          .where(docket: docket, priority: false)
          .where("distributed_cases.created_at >= ?", 1.week.ago)
          .order("appeals.receipt_date desc")
          &.first&.task&.appeal&.receipt_date,
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
        .where("receipt_date <= (?)", docket_result[:receipt_date])

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
    Rails.logger.tagged("rake db:affinity_start_date") do
      Rails.logger.info("The affinity_start_date rake task has been completed successfully")
    end
  end
end
