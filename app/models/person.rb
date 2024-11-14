# frozen_string_literal: true

class Person < CaseflowRecord
  include AssociatedBgsRecord
  include BgsService
  include EventConcern

  has_many :advance_on_docket_motions
  has_many :claimants, primary_key: :participant_id, foreign_key: :participant_id
  has_one :event_record, as: :evented_record
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
      return unless person.found?

      person.update_cached_attributes!
      person
    end

    def find_or_create_by_ssn(ssn)
      person = find_by(ssn: ssn)
      return person if person

      person = new(ssn: ssn)

      return unless person.found?

      # in order to correctly backfill ssn for existing Person records,
      # we do a 2nd search by participant_id
      if person.participant_id.present?
        person_with_pid = find_by(participant_id: person.participant_id)
        person = person_with_pid if person_with_pid
      end
      person.update_cached_attributes! if person.found?
      person
    end
  end

  def advanced_on_docket?(appeal)
    advanced_on_docket_based_on_age? || advanced_on_docket_motion_granted?(appeal)
  end

  def date_of_birth
    cached_or_fetched_from_bgs(attr_name: :date_of_birth)&.to_date
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
    cached_or_fetched_from_bgs(attr_name: :ssn)
  end

  def stale_attributes?
    return false unless found?

    stale_attributes.any?
  end

  def update_cached_attributes!
    transaction do
      CACHED_BGS_ATTRIBUTES.each { |attr| send(attr) }
      save!
    end
  end

  def advanced_on_docket_based_on_age?
    date_of_birth && date_of_birth < 75.years.ago
  end

  def advanced_on_docket_motion_granted?(appeal)
    AdvanceOnDocketMotion.granted_for_person?(id, appeal)
  end

  def found?
    return false if not_found?

    bgs_record.keys.any?
  end

  private

  def fetch_bgs_record
    if self[:participant_id]
      fetch_bgs_record_by_participant_id
    elsif self[:ssn]
      fetch_bgs_record_by_ssn
    else
      fail "Must provide participant_id or ssn"
    end
  end

  def fetch_bgs_record_by_participant_id
    bgs_record = bgs.fetch_person_info(participant_id)
    return :not_found unless bgs_record.keys.any?

    bgs_record[:date_of_birth] = bgs_record.dig(:birth_date)&.to_date
    bgs_record[:ssn] ||= bgs_record.dig(:ssn_nbr)
    bgs_record[:participant_id] ||= bgs_record.dig(:ptcpnt_id) || participant_id
    bgs_record
  end

  def fetch_bgs_record_by_ssn
    bgs_record = bgs.fetch_person_by_ssn(ssn)
    return :not_found unless bgs_record

    bgs_record[:date_of_birth] = bgs_record.dig(:brthdy_dt)&.to_date
    bgs_record[:ssn] ||= bgs_record.dig(:ssn_nbr) || ssn
    bgs_record[:participant_id] ||= bgs_record.dig(:ptcpnt_id)
    bgs_record[:first_name] ||= bgs_record.dig(:first_nm)
    bgs_record[:last_name] ||= bgs_record.dig(:last_nm)
    bgs_record[:middle_name] ||= bgs_record.dig(:middle_nm)
    bgs_record[:email_address] ||= bgs_record.dig(:email_addr)
    bgs_record
  end
end
