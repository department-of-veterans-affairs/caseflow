# frozen_string_literal: true

class BgsPowerOfAttorney < CaseflowRecord
  include AssociatedBgsRecord
  include BgsService

  class BgsPOANotFound < StandardError; end

  has_many :claimants, primary_key: :claimant_participant_id, foreign_key: :participant_id

  CACHED_BGS_ATTRIBUTES = [
    :representative_name,
    :representative_type,
    :authzn_change_clmant_addrs_ind,
    :authzn_poa_access_ind,
    :legacy_poa_cd,
    :poa_participant_id,
    :claimant_participant_id,
    :file_number
  ].freeze

  validates :claimant_participant_id,
            :poa_participant_id,
            :representative_name,
            :representative_type, presence: true

  before_save :update_cached_attributes!

  class << self
    # Neither file_number nor claimant_participant_id is unique by itself,
    # but we treat them that way for easy lookup. They are unique together in our db.
    # Since this is a cache we only want to mirror what BGS has and leave the
    # data integrity to them.
    def find_or_create_by_file_number(file_number)
      find_or_create_by!(file_number: file_number)
    end

    def find_or_create_by_claimant_participant_id(claimant_participant_id)
      find_or_create_by!(claimant_participant_id: claimant_participant_id)
    end

    def find_or_load_by_file_number(file_number)
      find_by(file_number: file_number) || new(file_number: file_number)
    end

    def fetch_bgs_poa_by_participant_id(pid)
      bgs.fetch_poas_by_participant_ids([pid])[pid]
    end
  end

  def representative_email_address
    person&.email_address
  end

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

  alias participant_id poa_participant_id

  def claimant_participant_id
    cached_or_fetched_from_bgs(attr_name: :claimant_participant_id)
  end

  def file_number
    cached_or_fetched_from_bgs(attr_name: :file_number)
  end

  def stale_attributes?
    return false if not_found?

    stale_attributes.any?
  end

  def update_cached_attributes!
    stale_attributes.each { |attr| send(attr) }
    self.last_synced_at = Time.zone.now
  end

  def save_with_updated_bgs_record!
    stale_attributes.each do |attr|
      self[attr] = nil # local object attr empty, should trigger re-fetch of bgs record
      send(attr)
    end
    save!
  end

  def found?
    return false if not_found?

    bgs_record.keys.any?
  end

  private

  def person
    return if poa_participant_id.blank?

    @person ||= Person.find_or_create_by_participant_id(poa_participant_id)
  end

  def fetch_bgs_record
    if self[:claimant_participant_id]
      fetch_bgs_record_by_claimant_participant_id
    elsif self[:file_number]
      fetch_bgs_record_by_file_number
    else
      fail BgsPOANotFound, "Must define claimant_participant_id or file_number"
    end
  end

  def fetch_bgs_record_by_claimant_participant_id
    pid = self[:claimant_participant_id]
    not_found_flag = "bgs-participant-poa-not-found-#{pid}"
    return if Rails.cache.fetch(not_found_flag)

    poa = self.class.fetch_bgs_poa_by_participant_id(pid)

    if poa.blank?
      Rails.cache.write(not_found_flag, true, expires_in: 24.hours)
      return
    end

    poa[:claimant_participant_id] ||= pid
    poa
  end

  def fetch_bgs_record_by_file_number
    file_number = self[:file_number]
    not_found_flag = "bgs-participant-poa-not-found-#{file_number}"
    return if Rails.cache.fetch(not_found_flag)

    poa = bgs.fetch_poa_by_file_number(file_number)

    if poa.blank?
      Rails.cache.write(not_found_flag, true, expires_in: 24.hours)
      return
    end

    poa
  end

  def load_bgs_address!
    return nil if !participant_id

    BgsAddressService.new(participant_id: poa_participant_id).address
  end
end
