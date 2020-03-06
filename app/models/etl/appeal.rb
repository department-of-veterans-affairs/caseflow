# frozen_string_literal: true

# transformed Appeal model, with associations "flattened" for reporting.

class ETL::Appeal < ETL::Record
  scope :active, -> { where(active_appeal: true) }

  has_many :tasks, -> { where(appeal_type: "Appeal") }, class_name: "ETL::Task", primary_key: "appeal_id"

  class << self
    def origin_primary_key
      :appeal_id
    end

    private

    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    # rubocop:disable Metrics/CyclomaticComplexity
    def merge_original_attributes_to_target(original, target)
      # memoize to save SQL calls
      veteran = original.veteran
      claimant = original.claimants.last
      person = claimant&.person
      aod = person&.advance_on_docket_motions&.last

      # avoid BGS call on sync for nil values
      person_attributes = (person&.attributes || {}).symbolize_keys
      veteran_person_attributes = (veteran&.person&.attributes || {}).symbolize_keys

      target.appeal_id = original.id
      target.active_appeal = original.active?
      target.aod_due_to_dob = person&.advanced_on_docket_based_on_age? || false
      target.aod_granted = aod&.granted? || false
      target.aod_reason = aod&.reason
      target.aod_user_id = aod&.user_id
      target.claimant_dob = person_attributes[:date_of_birth]
      target.claimant_first_name = person_attributes[:first_name]
      target.claimant_id = claimant&.id
      target.claimant_last_name = person_attributes[:last_name]
      target.claimant_name_suffix = person_attributes[:name_suffix]
      target.claimant_participant_id = claimant&.participant_id
      target.claimant_payee_code = claimant&.payee_code
      target.claimant_person_id = person&.id
      target.closest_regional_office = original.closest_regional_office
      target.decision_status_sort_key = original.status.to_i
      target.docket_number = original.docket_number
      target.docket_range_date = original.docket_range_date
      target.docket_type = original.docket_type
      target.established_at = original.established_at
      target.legacy_opt_in_approved = original.legacy_opt_in_approved
      target.poa_participant_id = original.poa_participant_id
      target.receipt_date = original.receipt_date
      target.status = original.status.to_s
      target.target_decision_date = original.target_decision_date
      target.uuid = original.uuid
      target.veteran_dob = veteran_person_attributes[:date_of_birth]
      target.veteran_file_number = original.veteran_file_number
      target.veteran_first_name = veteran&.first_name
      target.veteran_id = veteran&.id
      target.veteran_is_not_claimant = original.veteran_is_not_claimant
      target.veteran_last_name = veteran&.last_name
      target.veteran_middle_name = veteran&.middle_name
      target.veteran_name_suffix = veteran&.name_suffix
      target.veteran_participant_id = veteran&.participant_id

      target.appeal_created_at = original.created_at || Time.zone.now
      target.appeal_updated_at = original.updated_at || Time.zone.now

      target
    end
    # rubocop:enable Metrics/AbcSize
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/CyclomaticComplexity
  end
end
