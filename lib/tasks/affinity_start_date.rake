# frozen_string_literal: true

# # Value Statement:

# As a developer I need to add a Rake task to “seed” the initial affinity_start_date in all environments, including updating existing local/demo seed data, so that affinity day counters begin the hold period accurately based on the distribution of matching appeals, ensuring timely distribution to the affinitized judge.

# Acceptance Criteria:

# When the Rake task is executed, it retrieves the receipt_date for the most recent distributed appeals for each of the following docket types and priority statuses:
# Priority Direct Review Docket
# Priority Evidence Submission Docket
# Priority Hearing Request Docket
# Priority Legacy Docket
# Non-priority Direct Review Docket
# Non-priority Evidence Submission Docket
# Non-priority Hearing Request Docket
# Non-priority Legacy Docket
# Using the receipt_date obtained, the Rake task identifies all ready-to-distribute appeals of each corresponding type and priority status (priority or non-priority) with an affinity_start_date equal to or older than the retrieved receipt_date, or with no appeal_affinity record.
# The Rake task creates or updates the affinity_start_date records for the identified appeals, ensuring they align with the receipt_date of the most recent distributed appeals of their respective type and priority status.
# The Rake task completes successfully without errors and can be executed in all environments
namespace :db do
  desc "Generates a smattering of legacy appeals with VACOLS cases that have special issues assocaited with them"
  task affinity_start_date: :environment do
    dockets = %w[legacy hearing direct_review evidence_submission]
    docket_results = []

    dockets.each do |docket|
      docket_results << {
        receipt_date: DistributedCase.where(docket: docket, priority: true)&.first&.task&.appeal&.receipt_date,
        priority: true,
        docket_type: docket
      }
    end

    dockets.each do |docket|
      docket_results << {
        receipt_date: DistributedCase.where(docket: docket, priority: false)&.first&.task&.appeal&.receipt_date,
        priority: false,
        docket_type: docket
      }
    end

    docket_results.each do |docket_result|
      case docket_result[:docket_type]
      when "legacy"
        docket_instance = LegacyDocket.new
      when "hearing"
        docket_instance = HearingRequestDocket.new
      when "direct_review"
        docket_instance = DirectReviewDocket.new
      when "evidence_submission"
        docket_instance = EvidenceSubmissionDocket.new
      end

      appeals = Appeal.joins(:appeal_affinity)
        .where(docket_type: docket_result[:docket_type])
        .extending(DistributionScopes)
        .active
        .ready_for_distribution
        .where("affinity_start_date <= (?) OR case_id IS NULL", docket_result[:receipt_date])

      if docket_result[:priority] == true
        appeals.priority
      else
        appeals.nonpriority
      end

      next unless appeals

      appeals.each(&:appeal_affinity)

      # {}docket_instance.appeals(priority: docket_result[:priority], ready: true).where(receipt_date: docket_result[:receipt_date])
    end
  end
end
