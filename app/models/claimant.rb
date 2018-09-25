class Claimant < ApplicationRecord
  include AssociatedBgsRecord

  belongs_to :review_request, polymorphic: true

  bgs_attr_accessor :first_name, :last_name, :middle_name, :relationship

  def self.create_from_intake_data!(participant_id:, payee_code:)
    create!(
      participant_id: participant_id,
      payee_code: payee_code
    )
    Person.find_or_create_by(participant_id: participant_id).tap do |person|
      person.update!(date_of_birth: BGSService.new.fetch_person_info(participant_id)[:birth_date])
    end
  end

  def advanced_on_docket(appeal_receipt_date)
    advanced_on_docket_based_on_age || advanced_on_docket_motion_granted(appeal_receipt_date)
  end

  def power_of_attorney
    @bgs_power_of_attorney ||= BgsPowerOfAttorney.new(claimant_participant_id: participant_id)
  end
  delegate :representative_name, :representative_type, :representative_address, to: :power_of_attorney

  def representative_participant_id
    power_of_attorney.participant_id
  end

  def name
    FullName.new(first_name, "", last_name).formatted(:readable_short)
  end

  def bgs
    BGSService.new
  end

  def person
    @person ||= Person.find_or_create_by(participant_id: participant_id)
  end

  delegate :date_of_birth, :advance_on_docket_grants, to: :person
  delegate :address, :address_line_1, :address_line_2, :city, :country, :state, :zip, to: :bgs_address_service

  def fetch_bgs_record
    general_info = bgs.fetch_claimant_info_by_participant_id(participant_id)
    name_info = bgs.fetch_person_info(participant_id)

    general_info.merge(name_info)
  end

  private

  def bgs_address_service
    @bgs_address_service ||= BgsAddressService.new(participant_id: participant_id)
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
