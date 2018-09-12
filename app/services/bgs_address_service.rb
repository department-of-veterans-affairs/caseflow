class BgsAddressService
  include ActiveModel::Model
  include AssociatedBgsRecord

  attr_accessor :participant_id

  bgs_attr_accessor :address_line_1, :address_line_2, :city, :country, :state, :zip

  def fetch_bgs_record
    bgs.find_address_by_participant_id(participant_id)
  end

  def bgs
    BGSService.new
  end
end
