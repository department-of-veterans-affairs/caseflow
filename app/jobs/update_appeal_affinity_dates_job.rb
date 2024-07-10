# frozen_string_literal: true

class UpdateAppealAffinityDatesJob < CaseflowJob
  include DistributionScopes

  queue_with_priority :low_priority
  application_attr :queue

  # the ["docket_name", priority] format is how ActiveRecord returns the query results
  PAIRS_TO_DELETE = [["evidence_submission", false], ["direct_review", false]].freeze

  def perform(distribution_id = nil)
    RequestStore.store[:current_user] = User.system_user
    @distribution_id = distribution_id

    if @distribution_id
      update_from_requested_distribution
    else
      update_from_push_priority_appeals_job
    end
  rescue StandardError => error
    title = "UpdateAppealAffinityDatesJob Error"
    slack_service.send_notification(error.message, title)
    log_error(error)
  end

  private

  def update_from_requested_distribution
    receipt_date_hashes_array = latest_receipt_dates_from_distribution
    return if receipt_date_hashes_array.empty?

    process_ama_appeals_which_need_affinity_updates(receipt_date_hashes_array)
    # Uncomment this while implementing legacy appeal affinities
    # process_legacy_appeals_which_need_affinity_updates(receipt_date_hashes_array)
  end

  def update_from_push_priority_appeals_job
    receipt_date_hashes_array = latest_receipt_dates_from_push_job
    return if receipt_date_hashes_array.empty?

    process_ama_appeals_which_need_affinity_updates(receipt_date_hashes_array)
    # Uncomment this while implementing legacy appeal affinities
    # process_legacy_appeals_which_need_affinity_updates(receipt_date_hashes_array)
  end

  def latest_receipt_dates_from_distribution
    distributed_cases_hash =
      DistributedCase
        .joins("INNER JOIN appeals ON case_id = uuid::text")
        .where(distribution_id: @distribution_id)
        .group("docket", "priority")
        .maximum("receipt_date")

    format_distributed_case_hash(distributed_cases_hash)
  end

  def latest_receipt_dates_from_push_job
    distributed_cases_hash =
      DistributedCase
        .includes(:distribution)
        .joins("INNER JOIN appeals ON case_id = uuid::text")
        .where(distributions: { priority_push: true, completed_at: Time.zone.today.midnight..Time.zone.now })
        .group("docket", "priority")
        .maximum("receipt_date")

    format_distributed_case_hash(distributed_cases_hash)
  end

  def format_distributed_case_hash(distributed_cases_hash)
    # If there isn't a held hearing and it isn't a CAVC remand (priority), then there will never be an affinity
    distributed_cases_hash.delete_if { |combo, _| PAIRS_TO_DELETE.include?(combo) }

    # Transform the SQL output into a more workable array of hashes
    receipt_date_hashes_array = []
    distributed_cases_hash.each_pair do |keys, receipt_date|
      receipt_date_hashes_array << { docket: keys[0], priority: keys[1], receipt_date: receipt_date }
    end

    receipt_date_hashes_array
  end

  def process_ama_appeals_which_need_affinity_updates(receipt_date_hashes_array)
    receipt_date_hashes_array.map do |receipt_date_hash|
      next if receipt_date_hash[:docket] == LegacyDocket.docket_type

      base_appeals_to_update =
        Appeal.extending(DistributionScopes)
          .ready_for_distribution
          .with_appeal_affinities
          .where(docket_type: receipt_date_hash[:docket], appeal_affinities: { affinity_start_date: nil })
          .where("receipt_date <= (?)", receipt_date_hash[:receipt_date])

      appeals_to_update_adjusted_for_priority = if receipt_date_hash[:priority]
                                                  base_appeals_to_update.priority
                                                else
                                                  base_appeals_to_update.nonpriority
                                                end

      create_or_update_appeal_affinities(appeals_to_update_adjusted_for_priority, receipt_date_hash[:priority])
    end
  end

  # Returns only legacy appeals with no affinity record
  def legacy_appeals_with_no_appeal_affinities(appeals)
    appeals.select { |appeal| appeal.appeal_affinity.present? }
  end

  # To be implemented in future work
  def process_legacy_appeals_which_need_affinity_updates(receipt_date_hashes_array)
    receipt_date_hashes_array.map do |receipt_date_hash|
      next unless receipt_date_hash[:docket] == LegacyDocket.docket_type

      legacy_appeals_to_update_adjusted_for_priority = VACOLS::CaseDocket.update_appeal_affinity_dates(receipt_date_hash[:priority], receipt_date_hash[:receipt_date])
      create_or_update_appeal_affinities(legacy_appeals_to_update_adjusted_for_priority, receipt_date_hash[:priority])
    end
  end

  # The appeals arg can be an array of VACOLS::Case objects, they have the same affinity associations as Appeal objects
  def create_or_update_appeal_affinities(appeals, priority)
    appeals.map do |appeal|
      existing_affinity = appeal.appeal_affinity

      if existing_affinity
        existing_affinity.update!(affinity_start_date: Time.zone.now, distribution_id: @distribution_id)
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
