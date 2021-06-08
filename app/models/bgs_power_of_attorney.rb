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
  after_save :update_ihp_task, if: :update_ihp_enabled?

  class << self
    # Neither file_number nor claimant_participant_id is unique by itself,
    # but we treat them that way for easy lookup. They are unique together in our db.
    # Since this is a cache we only want to mirror what BGS has and leave the
    # data integrity to them.
    def find_or_create_by_file_number(file_number)
      poa = find_or_create_by!(file_number: file_number)
      if FeatureToggle.enabled?(:poa_auto_refresh)
        poa.save_with_updated_bgs_record! if poa&.expired?
      end
      poa
    rescue ActiveRecord::RecordNotUnique
      # We've noticed that this error is thrown because of a race-condition
      # where multiple processes are trying to create the same object.
      # see: https://dsva.slack.com/archives/C3EAF3Q15/p1593726968095600 for investigation
      # So a solution to this is to rescue the error and query it
      find_by(file_number: file_number)
    end

    def find_or_create_by_claimant_participant_id(claimant_participant_id)
      poa = find_or_create_by!(claimant_participant_id: claimant_participant_id)
      if FeatureToggle.enabled?(:poa_auto_refresh)
        poa.save_with_updated_bgs_record! if poa&.expired?
      end
      poa
    rescue ActiveRecord::RecordNotUnique
      # Handle race conditions similarly to find_or_create_by_file_number.
      # For an example of this in the wild, see Sentry event 17c302faae0b48bcb0e1816a58e8b7f5.
      find_by(claimant_participant_id: claimant_participant_id)
    end

    def find_or_load_by_file_number(file_number)
      find_by(file_number: file_number) || new(file_number: file_number)
    end

    def fetch_bgs_poa_by_participant_id(pid)
      bgs.fetch_poas_by_participant_ids([pid])[pid.to_s]
    end

    # Use participant_id and/or veteran_file_number to fetch a BgsPowerOfAttorney record that's
    # cached in Caseflow, hitting BGS if necessary. If neither Caseflow record nor BGS record is
    # found, return nil.
    def find_or_fetch_by(participant_id: nil, veteran_file_number: nil)
      if participant_id.present?
        begin
          return find_or_create_by_claimant_participant_id(participant_id)
        rescue ActiveRecord::RecordInvalid
          # not found in BGS
        end
      end
      if veteran_file_number.present?
        begin
          find_or_create_by_file_number(veteran_file_number)
        rescue ActiveRecord::RecordInvalid
          # not found in BGS
        end
      end
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
    stale_attributes.each { |attr| send(attr) } if found?
    self.last_synced_at = Time.zone.now
  end

  alias_attribute :poa_last_synced_at, :last_synced_at

  def save_with_updated_bgs_record!
    return save! unless found?

    stale_attributes.each do |attr|
      self[attr] = nil # local object attr empty, should trigger re-fetch of bgs record
      send(attr)
    end
    save!
  end

  def update_ihp_task
    appeals = Appeal.where(veteran_file_number: file_number, poa_participant_id: poa_participant_id)
    appeals.each do |appeal|
      InformalHearingPresentationTask.update_to_new_poa(appeal)
    end
  end

  def found?
    return false if not_found?

    bgs_record.keys.any?
  end

  def expired?
    last_synced_at && last_synced_at < 16.hours.ago
  end

  def update_or_delete(claimant)
    # If the BGS Power of Attorney record is not found, destroy it.
    if bgs_record == :not_found
      destroy!
      # If the claimaint's power of attorney record is also not found, destroy it.
      if !claimant.is_a?(Hash) && claimant.power_of_attorney&.bgs_record == :not_found
        claimant.power_of_attorney.destroy!
      end
      ["Successfully refreshed. No power of attorney information was found at this time.", "deleted"]
    else
      save_with_updated_bgs_record!
      ["POA Updated Successfully", "updated"]
    end
  end

  private

  def person
    return if poa_participant_id.blank?

    @person ||= Person.find_or_create_by_participant_id(poa_participant_id)
  end

  def fetch_bgs_record
    # prefer FN if both defined since one PID can have multiple FNs
    if self[:claimant_participant_id] && self[:file_number]
      fetch_bgs_record_by_file_number
    elsif self[:claimant_participant_id]
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

  def update_ihp_enabled?
    toggle_on = FeatureToggle.enabled?(:poa_auto_ihp_update, user: RequestStore.store[:current_user])
    Raven.capture_message("Checking if IHP should be updated..." \
    "Is feature toggle enabled for this user?: #{toggle_on}" \
    "Was there a POA participant ID change?: #{saved_change_to_poa_participant_id?}" \
    "POA participant ID: #{poa_participant_id}" \
    "File number: #{file_number}")
    toggle_on && saved_change_to_poa_participant_id?
  end
end
