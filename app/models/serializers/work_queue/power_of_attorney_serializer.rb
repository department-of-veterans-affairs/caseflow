# frozen_string_literal: true

class WorkQueue::PowerOfAttorneySerializer
  include FastJsonapi::ObjectSerializer
  attribute :id
  attribute :claimant_participant_id
  attribute :poa_participant_id
  attribute :representative_name
  attribute :representative_type
  attribute :file_number
  attribute :authzn_change_clmant_addrs_ind
  attribute :authzn_poa_access_ind
  attribute :legacy_poa_cd
  attribute :last_synced_at
  attribute :created_at
  attribute :updated_at


  attribute :ihp_allowed do |object|
    org = Organization.find_by(participant_id: object.poa_participant_id)
    !org.nil? && !(InformalHearingPresentationTask.NON_IHP_WRITING_ORG_TYPES.include? org.type)
  end
end
