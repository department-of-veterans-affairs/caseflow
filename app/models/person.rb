# frozen_string_literal: true

class Person < ApplicationRecord
  include BgsService

  has_many :advance_on_docket_motions
  has_many :claimants, primary_key: :participant_id, foreign_key: :participant_id
  validates :participant_id, presence: true

  def advanced_on_docket(appeal_receipt_date)
    advanced_on_docket_based_on_age || advanced_on_docket_motion_granted(appeal_receipt_date)
  end

  def date_of_birth
    cached_or_fetched_from_bgs(attr_name: :date_of_birth, bgs_attr: :birth_date)
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
    FullName.new(first_name, "", last_name)
  end

  private

  def cached_or_fetched_from_bgs(attr_name:, bgs_attr: nil)
    bgs_attr ||= attr_name
    self[attr_name] || begin
      return unless bgs_person

      update!(attr_name: bgs_person[bgs_attr]) if persisted?
      self[attr_name]
    end
  end

  def bgs_person
    @bgs_person ||= bgs.fetch_person_info(participant_id)
  end

  def advanced_on_docket_based_on_age
    date_of_birth && date_of_birth < 75.years.ago
  end

  def advanced_on_docket_motion_granted(appeal_receipt_date)
    advance_on_docket_motions.any? do |advance_on_docket_motion|
      advance_on_docket_motion.granted && appeal_receipt_date < advance_on_docket_motion.created_at
    end
  end
end
