# frozen_string_literal: true

class BgsPowerOfAttorney < CaseflowRecord
  include AssociatedBgsRecord
  include BgsService

  has_many :claimants, primary_key: :claimant_participant_id, foreign_key: :participant_id

  CACHED_BGS_ATTRIBUTES = [
    :representative_name,
    :representative_type,
    :authzn_change_clmant_addrs_ind,
    :authzn_poa_access_ind,
    :legacy_poa_cd
  ].freeze

  delegate :email_address,
           to: :person, prefix: :representative

  CACHE_TTL = 30.days

  def representative_name
    cached_or_fetched_from_bgs(attr_name: :representative_name)
  end

  def representative_type
    cached_or_fetched_from_bgs(attr_name: :representative_type)
  end

  def authzn_change_clmant_addrs_ind
    cached_or_fetched_from_bgs(attr_name: :authzn_change_clmant_addrs_ind)
  end

  def authzn_poa_access_ind
    cached_or_fetched_from_bgs(attr_name: :authzn_poa_access_ind)
  end

  def legacy_poa_cd
    cached_or_fetched_from_bgs(attr_name: :legacy_poa_cd)
  end

  def representative_address
    @representative_address ||= load_bgs_address!
  end

  def poa_participant_id
    cached_or_fetched_from_bgs(attr_name: :poa_participant_id, bgs_attr: :participant_id)
  end

  def stale_attributes?
    return false if bgs_record == :not_found

    stale_attributes.any?
  end

  def update_cached_attributes!
    transaction do
      CACHED_BGS_ATTRIBUTES.each { |attr| send(attr) }
    end
  end

  private

  def person
    @person ||= Person.find_or_create_by(participant_id: poa_participant_id)
  end

  def stale_attributes
    CACHED_BGS_ATTRIBUTES.select { |attr| self[attr].nil? || self[attr] != bgs_record[attr] }
  end

  def cached_or_fetched_from_bgs(attr_name:, bgs_attr: nil)
    bgs_attr ||= attr_name
    self[attr_name] || begin
      return unless bgs_record

      update!(attr_name => bgs_record[bgs_attr]) if persisted?
      self[attr_name]
    end
  end

  def fetch_bgs_record
    if claimant_participant_id
      bgs.fetch_poas_by_participant_ids([claimant_participant_id])[claimant_participant_id]
    else
      bgs.fetch_poa_by_file_number(file_number)
    end
  end

  def load_bgs_address!
    return nil if !participant_id

    BgsAddressService.new(participant_id: poa_participant_id).address
  end
end
