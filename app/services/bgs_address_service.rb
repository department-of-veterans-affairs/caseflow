class BgsAddressService
  include ActiveModel::Model
  include AssociatedBgsRecord

  attr_accessor :participant_id

  bgs_attr_accessor :address_line_1, :address_line_2, :city, :country, :state, :zip

  def fetch_bgs_record
    begin
      bgs.find_address_by_participant_id(participant_id)
    rescue Savon::Error => e
      # If there is no addresses for this participant id then we get an error.
      # catch it and return an empty array
      {}
    end
  end

  def bgs
    BGSService.new
  end
end
