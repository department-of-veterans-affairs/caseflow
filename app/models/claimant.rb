class Claimant < ApplicationRecord
  include AssociatedBgsRecord

  belongs_to :review_request, polymorphic: true

  bgs_attr_accessor :name, :relationship,
                    :address_line_1, :address_line_2, :city, :country, :state, :zip

  def self.create_from_intake_data!(data)
    create!(
      participant_id: data
    )
  end

  def self.bgs
    BGSService.new
  end

  def fetch_bgs_record
    bgs_record = self.class.bgs.find_address_by_participant_id(participant_id)
    general_info = self.class.bgs.fetch_claimant_info_by_participant_id(participant_id)

    bgs_record.merge(general_info)
  end
end
