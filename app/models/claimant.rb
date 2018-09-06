class Claimant < ApplicationRecord
  include AssociatedBgsRecord

  belongs_to :review_request, polymorphic: true

  bgs_attr_accessor :first_name, :last_name, :middle_name, :relationship,
                    :address_line_1, :address_line_2, :city, :country, :state, :zip

  def self.create_from_intake_data!(participant_id:, payee_code:)
    create!(
      participant_id: participant_id,
      payee_code: payee_code
    )
  end

  def power_of_attorney
    BgsPowerOfAttorney.new(claimant_participant_id: participant_id)
  end
  delegate :representative_name, :representative_type, :representative_address, to: :power_of_attorney

  def name
    FullName.new(first_name, "", last_name)
  end

  def name_suffix
    ""
  end

  def self.bgs
    BGSService.new
  end

  def fetch_bgs_record
    bgs_record = self.class.bgs.find_address_by_participant_id(participant_id)
    general_info = self.class.bgs.fetch_claimant_info_by_participant_id(participant_id)
    name_info = self.class.bgs.fetch_person_info(participant_id)

    bgs_record.merge(general_info).merge(name_info)
  end
end
