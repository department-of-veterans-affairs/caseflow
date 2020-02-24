# frozen_string_literal: true

class BgsPowerOfAttorney
  include ActiveModel::Model
  include AssociatedBgsRecord
  include BgsService

  attr_accessor :file_number
  attr_accessor :claimant_participant_id

  bgs_attr_accessor :representative_name, :representative_type, :participant_id

  def representative_address
    @representative_address ||= load_bgs_address!
  end

  delegate :email_address,
           to: :person, prefix: :representative

  private

  def person
    @person ||= Person.find_or_create_by(participant_id: participant_id)
  end

  def fetch_bgs_record
    if claimant_participant_id
      cache_key = "bgs-participant-poa-#{claimant_participant_id}"
      Rails.cache.fetch(cache_key, expires_in: 30.days) do
        bgs.fetch_poas_by_participant_ids([claimant_participant_id])[claimant_participant_id]
      end
    else
      cache_key = "bgs-participant-poa-#{file_number}"
      Rails.cache.fetch(cache_key, expires_in: 30.days) do
        bgs.fetch_poa_by_file_number(file_number)
      end
    end
  end

  def load_bgs_address!
    return nil if !participant_id

    BgsAddressService.new(participant_id: participant_id).address
  end
end
