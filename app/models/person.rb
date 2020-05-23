# frozen_string_literal: true

class Person < CaseflowRecord
  include AssociatedBgsRecord
  include BgsService

  has_many :advance_on_docket_motions
  has_many :claimants, primary_key: :participant_id, foreign_key: :participant_id
  validates :participant_id, presence: true

  CACHED_BGS_ATTRIBUTES = [
    :first_name,
    :last_name,
    :middle_name,
    :name_suffix,
    :date_of_birth,
    :email_address,
    :ssn,
    :participant_id
  ].freeze

  class << self
    def find_or_create_by_participant_id(participant_id)
      person = find_by(participant_id: participant_id)
      return person if person

      person = new(participant_id: participant_id)
      person.update_cached_attributes! if person.found?
      person
    end

    def find_or_create_by_ssn(ssn)
      person = find_by(ssn: ssn)
      return person if person

      person = new(ssn: ssn)
      person.update_cached_attributes! if person.found?
      person
    end
  end

  def advanced_on_docket?(appeal_receipt_date)
    advanced_on_docket_based_on_age? || AdvanceOnDocketMotion.granted_for_person?(id, appeal_receipt_date)
  end

  def date_of_birth
    cached_or_fetched_from_bgs(attr_name: :date_of_birth, bgs_attr: :birth_date)&.to_date
  end

  def first_name
    cached_or_fetched_from_bgs(attr_name: :first_name)
  end

  def last_name
    cached_or_fetched_from_bgs(attr_name: :last_name)
  end

  def middle_name
    cached_or_fetched_from_bgs(attr_name: :middle_name)
  end

  def name_suffix
    cached_or_fetched_from_bgs(attr_name: :name_suffix)
  end

  def name
    FullName.new(first_name, "", last_name).formatted(:readable_short)
  end

  def email_address
    cached_or_fetched_from_bgs(attr_name: :email_address)
  end

  def participant_id
    cached_or_fetched_from_bgs(attr_name: :participant_id, bgs_attr: :ptcpnt_id)
  end

  def ssn
    cached_or_fetched_from_bgs(attr_name: :ssn, bgs_attr: :ssn_nbr)
  end

  def stale_attributes?
    return false unless found?

    stale_attributes.any?
  end

  def update_cached_attributes!
    transaction do
      CACHED_BGS_ATTRIBUTES.each { |attr| send(attr) }
    end
    save!
  end

  def advanced_on_docket_based_on_age?
    date_of_birth && date_of_birth < 75.years.ago
  end

  def found?
    return false if not_found?

    bgs_record.keys.any?
  end

  private

  def fetch_bgs_record
    if self[:participant_id]
      bgs_record = bgs.fetch_person_info(participant_id)
      bgs_record[:date_of_birth] = bgs_record.dig(:birth_date)&.to_date
      bgs_record
    elsif self[:ssn]
      bgs_record = bgs.fetch_person_by_ssn(ssn)
      bgs_record[:date_of_birth] = bgs_record.dig(:brthdy_dt)&.to_date
      bgs_record[:ssn] = bgs_record.dig(:ssn_nbr)
      bgs_record[:participant_id] = bgs_record.dig(:ptcpnt_id)
      bgs_record
    else
      fail "Must provide participant_id or ssn"
    end
  end
end
