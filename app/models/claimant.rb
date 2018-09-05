class Claimant < ApplicationRecord
  include AssociatedBgsRecord

  belongs_to :review_request, polymorphic: true
  has_many :advance_on_docket_grants

  bgs_attr_accessor :name, :relationship,
                    :address_line_1, :address_line_2, :city, :country, :state, :zip

  def self.create_from_intake_data!(participant_id:, payee_code:)
    create!(
      participant_id: participant_id,
      payee_code: payee_code,
      date_of_birth: BGSService.new.fetch_person_info(participant_id)[:brthdy_dt]
    )
  end

  def advanced_on_docket
    advance_on_docket_grants.any? do |advance_on_docket_grant|
      receipt_date < advanced_on_docket.created_at
    end

    date_of_birth < 75.years.ago || advanced_on_docket_granted
  end

  def bgs
    BGSService.new
  end

  def fetch_bgs_record
    bgs_record = bgs.find_address_by_participant_id(participant_id)
    general_info = bgs.fetch_claimant_info_by_participant_id(participant_id)

    bgs_record.merge(general_info)
  end
end
